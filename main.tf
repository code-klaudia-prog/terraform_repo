
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

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "example" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  tags = {
    Name = "HelloWorld"
  }
}

resource "ssm_command" "greeting" {
  document_name = "AWS-RunShellScript"
  parameters {
    name   = "commands"
    values = ["echo 'Hello World!'"]
  }
  destroy_document_name = "AWS-RunShellScript"
  destroy_parameters {
    name   = "commands"
    values = ["echo 'Goodbye World.'"]
  }
  targets {
    key    = "InstanceIds"
    values = [aws_instance.example.id]
  }
  comment           = "Greetings from SSM!"
  execution_timeout = 600
  output_location {
    s3_bucket_name = aws_s3_bucket.output.bucket
    s3_key_prefix  = "greetings"
  }
}
