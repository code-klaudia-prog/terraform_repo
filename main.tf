
# 1. Configuração do Provedor AWS (Onde os seus recursos de nuvem serão criados)
provider "aws" {
  region = "us-east-1" 
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0.0"
    }
  }
}

# Create a new VPC
resource "aws_vpc" "my_custom_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "ssm"
  }
}

# Create a Public Subnet within the VPC
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.my_custom_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true # This allows the EC2 instance to get a public IP
  availability_zone       = "us-east-1a"
  tags = {
    Name = "ssm"
  }
}

# Create an Internet Gateway (IGW)
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_custom_vpc.id
  tags = {
    Name = "ssm"
  }
}

resource "aws_security_group" "ssh_access" {
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
  }
}

resource "aws_security_group_rule" "example" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [aws_vpc.my_custom_vpc.cidr_block]
  ipv6_cidr_blocks  = [aws_vpc.my_custom_vpc.ipv6_cidr_block]
  security_group_id = aws_security_group.ssh_access
}

resource "aws_instance" "example2" {
  ami           = "ami-052064a798f08f0d3"
  instance_type = "t3.micro"
  vpc_security_group_ids = [
    aws_security_group.ssh_access.id
  ]
}

resource "aws_vpc_security_group_vpc_association" "example2" {
  security_group_id = aws_security_group.ssh_access.id
  vpc_id            = aws_vpc.my_custom_vpc.id
}

resource "aws_ssm_document" "that" {
  name = "bptest"
  content = jsonencode({
    schemaVersion = "2.2"
    description   = "BPTest"
    parameters = {
      name = {
        type        = "String"
        description = "Name"
        default     = "World"
      }
    }
    mainSteps = [
      {
        precondition = {
          StringEquals = [
            "platformType",
            "Linux"
          ]
        }
        action = "aws:runShellScript",
        name   = "Test",
        inputs = {
          runCommand = [
            "echo Hello {{ name }} && sleep 10s && exit 0"
          ]
        }
      }
    ]
  })
  document_type = "Command"
}

resource "aws_ssm_document" "bar" {
  name          = "test_document"
  document_type = "Command"

  content = <<DOC
  {
    "schemaVersion": "1.2",
    "description": "Check ip configuration of a Linux instance.",
    "parameters": {

    },
    "runtimeConfig": {
      "aws:runShellScript": {
        "properties": [
          {
            "id": "0.aws:runShellScript",
            "runCommand": ["ifconfig"]
          }
        ]
      }
    }
  }
DOC
}
