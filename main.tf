
# Define o provedor AWS
provider "aws" {
  region = "us-east-1"  # Região onde os recursos serão criados
}

# Cria uma aplicação Elastic Beanstalk
resource "aws_elastic_beanstalk_application" "my_application" {
  name        = "my-terraform-app"
  description = "Aplicação de exemplo criada com Terraform"
}

# Cria um ambiente Elastic Beanstalk para a aplicação
resource "aws_elastic_beanstalk_environment" "my_environment" {
  name                = "envclaudia"
  application         = aws_elastic_beanstalk_application.my_application.name
  solution_stack_name = "64bit Amazon Linux 2023 running Node.js 22"# Exemplo de stack. Você pode alterá-lo.

  # Configurações do ambiente
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

# Output para exibir o CNAME do ambiente após a criação
output "environment_cname" {
  value = aws_elastic_beanstalk_environment.my_environment.cname
}
