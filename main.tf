
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

resource "aws_security_group" "ssh_access" {
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
  }
}

resource "aws_instance" "example2" {
  ami           = "ami-052064a798f08f0d3"
  instance_type = "t3.micro"
  # vpc_security_group_ids = [
  #  aws_security_group.ssh_access.id
  # ]
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
