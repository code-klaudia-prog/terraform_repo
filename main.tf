
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

data "aws_elastic_beanstalk_hosted_zone" "current" {}

resource "aws_elastic_beanstalk_application" "example" {
  name = var.application_name
  description      = var.application_name
}

resource "aws_vpc" "minha_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "public_subnet_a" {
  vpc_id            = aws_vpc.minha_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true  # Permite que as instâncias recebam IPs públicos
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id            = aws_vpc.minha_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b" # Altere para a sua região e AZ
  map_public_ip_on_launch = true
}

resource "aws_elastic_beanstalk_environment" "beanstalkappenv" {
  name                ="${var.app_tags}-Api"
  application         = aws_elastic_beanstalk_application.example.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.7.2 running Python 3.11"
  wait_for_ready_timeout = "60m"
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     =  "aws-elasticbeanstalk-ec2-role"
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = var.vpc_id
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = join(",", [
      aws_subnet.public_a.id,
      aws_subnet.public_b.id
    ])
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     =  "aws-elasticbeanstalk-ec2-role"
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = "a..ws-elasticbeanstalk-service-role"
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "AssociatePublicIpAddress"
    value     =  "True"
  }
}
