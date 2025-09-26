# Summary: Create a simple AWS RDS DB Instance with MySQL

# Documentation: https://www.terraform.io/docs/language/settings/index.html
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.38"
    }
  }
}

# Documentation: https://www.terraform.io/docs/language/providers/requirements.html
provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      cs_terraform_examples = "aws_db_instance/simple"
    }
  }
}

data "aws_elastic_beanstalk_hosted_zone" "current" {}


resource "aws_elastic_beanstalk_application" "elasticapp" {
  name = var.application_name
}

resource "aws_elastic_beanstalk_environment" "beanstalkappenv" {
  name                ="${var.app_tags}-Api"
  application         = var.application_name
  solution_stack_name = "64bit Amazon Linux 2 v3.8.4 running PHP 8.0"
 }
