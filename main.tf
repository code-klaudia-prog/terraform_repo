
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

module "ssm_runcommand_linux_example_1" {
  source = "../../../ssm_runcommand_module"
  # The following parameters are required:
  instance_id = aws_instance.amazon_linux_instance.id
  target_os   = "unix"
  command     = "whoami"
  # The following parameters are optional:
  show_command_output         = true
  wait_for_command_completion = true
  log_file                    = "${path.cwd}/ssm_runcommand_linux_example_1.log"
}
