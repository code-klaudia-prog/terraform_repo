
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

resource "aws_instance" "example" {
  ami           = "ami-052064a798f08f0d3"
  instance_type = "t3.micro"
}

module "ssm_runcommand_unix" {
  source                      = "github.com/paololazzari/terraform-ssm-runcommand"
  instance_id                 = aws_instance.example.id
  target_os                   = "unix"
  command                     = "ps -ax | grep 'amazon*'"
  wait_for_command_completion = true
  environment = {
    AWS_REGION = "us-east-1" 
  }
}
