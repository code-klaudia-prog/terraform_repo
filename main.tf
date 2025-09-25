
# Define o provedor AWS
provider "aws" {
  region = "us-east-1"  # Região onde os recursos serão criados
}

# Cria uma aplicação Elastic Beanstalk
resource "aws_elastic_beanstalk_application" "my_application" {
  name        = "claudiaapp"
  description = "Aplicação de exemplo criada com Terraform"
}

resource "aws_elastic_beanstalk_environment" "docker-env" {
  name                = "Docker-env3"
  application         = aws_elastic_beanstalk_application.my_application.name
  solution_stack_name = "64bit Amazon Linux 2 v3.4.1 running PHP 8.0"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t2.micro" # Exemplo de tipo de instância
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = "1"
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = "1"
  }
}
