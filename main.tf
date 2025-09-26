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

module "dns_and_ssl" {

  source = "./modules/dns_and_ssl/"
  
  
  domain_name                                           = var.domain_name
  cname                                                 = module.eb.cname
  zone                                                  = module.eb.zone
}

module "eb" {

  source = "./modules/beanstalk/"
  
  
  app_tags                          = var.app_tags
  application_name                  = var.application_name
  vpc_id                            = var.vpc_id
  ec2_subnets                       = var.ec2_subnets
  elb_subnets                       = var.elb_subnets
  instance_type                     = var.instance_type
  disk_size                         = var.disk_size
  keypair                           = var.keypair
  sshrestrict                       = var.sshrestrict
  certificate                       = module.dns_and_ssl.certificate
}
