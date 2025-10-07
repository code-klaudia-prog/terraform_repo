
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
    cidr_blocks = var.private_subnet ? ["${ aws_subnet.public_subnet_1.cidr_block}"  ] : ["0.0.0.0/0"]
    description = "allow outbound traffic over 443"
  }

  vpc_id = aws_vpc.minha_vpc.id

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
