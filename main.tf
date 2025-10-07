
# 1. Configuração do Provedor AWS (Onde os seus recursos de nuvem serão criados)
provider "aws" {
  region = "us-east-1" 
}

# 2. Configuração do Provedor TFE
terraform {
  required_version = ">= 0.13.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0.0"
    }
  }
}

resource "aws_instance" "example" {
  ami           = "ami-052064a798f08f0d3"
  instance_type = "t3.micro"
}

terraform {
  required_providers {
    risqaws = {
      source = "github.com/risqcapital/risq-aws"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.81.0"
    }
  }
}

resource "aws_ssm_document" "this" {
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

resource "risqaws_ssm_command" "this" {
  document_name    = aws_ssm_document.this.name
  document_version = aws_ssm_document.this.latest_version
  targets {
    key    = aws_instance.example.id
    values = [aws_instance.example.id]
  }
  parameters = {
    "name" = "test"
  }

  lifecycle {
    replace_triggered_by = [
      aws_ssm_document.this.latest_version,
    ]
  }
}
