# Define o provedor AWS
provider "aws" {
  region = "us-east-1"  # Região onde os recursos serão criados
}

resource "aws_elastic_beanstalk_application" "eb_appl" {
  name        = var.eb_app_name
  description = "Claudia has built this application"
}

resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

data "aws_subnets" "default_subs" {
  filter {
    name   = "vpc-id"
    values = [aws_default_vpc.default.id]
  }
}

resource "aws_elastic_beanstalk_configuration_template" "tf_template" {
  name                = "tf-test-template-config"
  application         = aws_elastic_beanstalk_application.eb_appl.name
  solution_stack_name = "64bit Amazon Linux 2023 running Python 3.13"
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_default_vpc.default.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = join(",", data.aws_subnets.default_subs.ids)
  }

  setting {
      namespace = "aws:ec2:instances"
      name = "InstanceTypes"
      value = "t4g.micro"
  }

  setting {
      namespace = "aws:ec2:instances"
      name = "SupportedArchitectures"
      value = "arm64"
  }

  setting {
      namespace = "aws:autoscaling:asg"
      name = "MinSize"
      value = 1
  }

  setting {
      namespace = "aws:autoscaling:asg"
      name = "MaxSize"
      value = 2
  }

  setting {
      namespace = "aws:elasticbeanstalk:environment"
      name = "EnvironmentType"
      value = "LoadBalanced"
  }
}

resource "aws_elastic_beanstalk_environment" "tfenvtest" {
  name                = var.eb_env_name
  application         = aws_elastic_beanstalk_application.eb_appl.name
  template_name = aws_elastic_beanstalk_configuration_template.tf_template.name
  version_label = var.app_version
  
}
