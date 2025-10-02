
# 1. Configuração do Provedor AWS (Onde os seus recursos de nuvem serão criados)
provider "aws" {
  region = "us-east-1" 
}

# 2. Configuração do Provedor TFE (Para interagir com o Terraform Cloud API)
terraform {
  required_version = ">= 0.12"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0.0"
    }
  }
}

resource "aws_vpc" "minha_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}
 
resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.minha_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true  # Permite que as instâncias recebam IPs públicos
}
 
resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.minha_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b" # Altere para a sua região e AZ
  map_public_ip_on_launch = true
}

#### Create the IAM role for the instance profile ####

resource "aws_iam_role" "ssm_role" {
  name = "${var.ssm_role}-${var.team}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EC2AssumeRole"
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    ssmdemo = "true"
  }
}

#### Create Policy to allow instance profile to put objects in the S3 bucket ####

resource "aws_iam_policy" "ec2_policy" {
  name        = "ssm_logs_policy_${data.aws_region.current.name}_${data.aws_caller_identity.current.account_id}"
  description = "Policy allowing put and get operations for ec2 to place session logs in specified bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:PutObjectAcl"

        ]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.ssm_s3_bucket.arn}/*"
      },
    ]
  })
}

resource "aws_iam_policy_attachment" "s3_attach" {
  name       = "ssm-s3-put"
  roles      = [aws_iam_role.ssm_role.name]
  policy_arn = aws_iam_policy.ec2_policy.arn

}

resource "aws_iam_policy_attachment" "ssm-attach" {
  name       = "managed-ssm-policy-attach"
  roles      = [aws_iam_role.ssm_role.name]
  policy_arn = var.ssm_policy_arn
}

#### Create the S3 bucket ####

resource "aws_s3_bucket" "ssm_s3_bucket" {
  bucket              =  "ssm_s3_bucket"
  object_lock_enabled = true
  tags = {
    name     = "ssm-logs"
    DataType = "SENSITIVE"
  }
}

#### Enable versioning on the bucket ####

resource "aws_s3_bucket_versioning" "versioning_s3" {
  bucket = aws_s3_bucket.ssm_s3_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

#### Configure block public access policies on the bucket ####

resource "aws_s3_bucket_public_access_block" "block_public_s3" {
  bucket = aws_s3_bucket.ssm_s3_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#### Create the EC2 instance with AWS managed KMS key for EBS volume encryption ####
#### Must have associate_public_ip_address set to true unless assignment is handled within the subnet ####

data "aws_vpc" "desired_vpc" {
  id = aws_vpc.minha_vpc.id
}

data "aws_subnet" "ec2_subnet" {
  id = aws_subnet.public_subnet_1.id
}

data "aws_route_table" "subnet_rt" {
  vpc_id = aws_vpc.minha_vpc.id
  filter {
    name   = "association.main"
    values = ["true"]
  }
}

resource "aws_instance" "ssm_instance" {
  ami                    = "ami-052064a798f08f0d3"
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.http_allow.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name
  monitoring             = true
  subnet_id              = aws_subnet.public_subnet_1.id
  associate_public_ip_address = var.private_subnet ? false : true

  root_block_device {
    encrypted  = true
  }

  metadata_options {
    http_tokens                 = "required"
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "disabled"
  }
}

#### Create the instance profile to attach to the instance ####

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "ssm-ec2-profile-${var.team}"
  role = aws_iam_role.ssm_role.name
}

#### Create the security group to allow EC@ outbound traffic over 443 to interact with session manager ####

resource "aws_security_group" "http_allow" {
  name        = var.security_group
  description = "Security group to allow traffic over HTTPS 443"
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "allow outbound traffic over 443"
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.private_subnet ? ["${data.aws_subnet.ec2_subnet.cidr_block}"  ] : ["0.0.0.0/0"]
    description = "allow outbound traffic over 443"
  }

  vpc_id = data.aws_vpc.desired_vpc.id

}

resource "aws_vpc_endpoint" "s3-endpt" {
  count = var.private_subnet ? 1 : 0
  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
  route_table_ids = [data.aws_route_table.subnet_rt.id]
}

resource "aws_vpc_endpoint" "ssm-endpt" {
  count = var.private_subnet ? 1 : 0
  vpc_id       = var.vpc_id
  vpc_endpoint_type = "Interface"
  security_group_ids = [
    aws_security_group.http_allow.id
  ]
  subnet_ids        = [aws_subnet.public_subnet_1.id]
  private_dns_enabled = true
  service_name = "com.amazonaws.${data.aws_region.current.name}.ssm"
}

resource "aws_vpc_endpoint" "ssmmsgs-endpt" {
  count = var.private_subnet ? 1 : 0
  vpc_id       = var.vpc_id
  vpc_endpoint_type = "Interface"
  security_group_ids = [
    aws_security_group.http_allow.id
  ]
  subnet_ids        = [aws_subnet.public_subnet_1.id]
  private_dns_enabled = true
  service_name = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
}

resource "aws_vpc_endpoint" "ec2msgs-endpt" {
  count = var.private_subnet ? 1 : 0
  vpc_id       = var.vpc_id
  vpc_endpoint_type = "Interface"
  security_group_ids = [
    aws_security_group.http_allow.id
  ]
  subnet_ids        = [aws_subnet.public_subnet_1.id]
  private_dns_enabled = true
  service_name = "com.amazonaws.${data.aws_region.current.name}.ec2messages"
}
