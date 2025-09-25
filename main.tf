
# Define o provedor AWS
provider "aws" {
  region = "us-east-1"  # Região onde os recursos serão criados
}

resource "aws_elastic_beanstalk_environment" "environment" {
  name                = "php-hello-world-environment"
  application         = aws_elastic_beanstalk_application.application.name
  solution_stack_name = "64bit Amazon Linux 2 v3.1.2 running PHP 7.3"
}
