# Define o provedor AWS
provider "aws" {
  region = "us-east-1"  # Região onde os recursos serão criados
}

# Cria uma aplicação Elastic Beanstalk
resource "aws_elastic_beanstalk_application" "my_application" {
  name        = "claudiaapp"
  description = "Aplicação de exemplo criada com Terraform"
}

# Cria um ambiente Elastic Beanstalk para a aplicação
resource "aws_elastic_beanstalk_environment" "my_environment" {
  name                = "envclaudia"
  application         = aws_elastic_beanstalk_application.my_application.name
  solution_stack_name = "Amazon Linux running Tomcat 6"
}
