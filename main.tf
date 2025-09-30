
# 1. Configuração do Provedor AWS (Onde os seus recursos de nuvem serão criados)
provider "aws" {
  region = "us-east-1" 
}

# 2. Configuração do Provedor TFE (Para interagir com o Terraform Cloud API)
terraform {
  required_providers {
    # Define a fonte e a versão do provedor TFE
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.70.0"
    }
  }
}

#### Create the S3 bucket ####

resource "aws_s3_bucket" "ssm_s3_bucket" {
  bucket              = "${var.s3_bucket}-${data.aws_caller_identity.current.id}-${data.aws_region.current.name}"
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

data "aws_subnet" "ec2_subnet" {
  id = var.subnet_id
}

data "aws_route_table" "subnet_rt" {
  subnet_id = var.subnet_id
}

resource "aws_instance" "ssm_instance" {
  ami                    = var.ami
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.http_allow.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name
  monitoring             = true
  subnet_id              = var.subnet_id
  associate_public_ip_address = var.private_subnet ? false : true
  tags = merge(
    var.tags,
    {
      Name = "cloud-security-ec2"
    }
  )

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
  subnet_ids        = [var.subnet_id]
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
  subnet_ids        = [var.subnet_id]
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
  subnet_ids        = [var.subnet_id]
  private_dns_enabled = true
  service_name = "com.amazonaws.${data.aws_region.current.name}.ec2messages"
}
