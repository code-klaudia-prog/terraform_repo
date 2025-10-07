
# 1. Configuração do Provedor AWS (Onde os seus recursos de nuvem serão criados)
provider "aws" {
  region = "us-east-1" 
}

# 2. Configuração do Provedor TFE (Para interagir com o Terraform Cloud API)
terraform {
  required_version = ">= 0.13.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0.0"
    }
  }
}

provisioner "local-exec" {
  command = "bash util/ssm_run_command.sh i-0ab9b235ecc2efe4c unix \"ps -ax | grep 'amazon*'\" true 60 false false \"\" \"\" \"\" \"\" \"\" \"\" \"\" \"\" \"\""
  environment = {
    AWS_REGION = "us-east-1"
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
}
