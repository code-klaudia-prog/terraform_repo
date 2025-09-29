
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


# Policy de Confiança para permitir que as instâncias EC2 assumam a função
data "aws_iam_policy_document" "eb_ec2_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# Criação do EC2 Role
resource "aws_iam_role" "eb_ec2_role" {
  name               = "aws-elasticbeanstalk-ec2-role-claudia"
  assume_role_policy = data.aws_iam_policy_document.eb_ec2_assume_role.json
}

# Anexa a política gerida da AWS para o perfil de instância do Elastic Beanstalk
resource "aws_iam_role_policy_attachment" "eb_ec2_policy_attach_managed" {
  role       = aws_iam_role.eb_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

# **OPCIONAL mas RECOMENDADO:** Anexar uma segunda política (se necessário para *worker environments* ou logs)
resource "aws_iam_role_policy_attachment" "eb_ec2_policy_attach_worker" {
  role       = aws_iam_role.eb_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
}

# Criação do IAM Instance Profile que as instâncias EC2 irão usar
resource "aws_iam_instance_profile" "eb_instance_profile" {
  name = "aws-elasticbeanstalk-ec2-role"
  role = aws_iam_role.eb_ec2_role.name
}

# 1. Criação do Internet Gateway (IGW)
# O IGW permite a comunicação entre a VPC e a Internet.
resource "aws_internet_gateway" "main_igw" {
  # 'var.vpc_id' deve ser a variável ou referência à sua VPC existente.
  # Se criou a VPC no Terraform, use a referência, ex: aws_vpc.minha_vpc.id
  vpc_id = var.vpc_id # Altere para a sua referência de VPC

  tags = {
    Name = "igw-para-elasticbeanstalk"
  }
}

# 2. Atualização da Tabela de Rotas Pública
# Adiciona uma rota 0.0.0.0/0 (todo o tráfego) para o Internet Gateway na Tabela de Rotas pública

resource "aws_route" "default_internet_route" {
  # 'var.public_route_table_id' deve ser a referência à sua Tabela de Rotas pública.
  # Se criou a Tabela de Rotas no Terraform, use a referência, ex: aws_route_table.public.id
  route_table_id         = var.public_route_table_id # Altere para a sua referência de Tabela de Rotas
  
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main_igw.id
  
  # Adicionar depends_on para garantir que o IGW é criado antes da rota
  depends_on = [
    aws_internet_gateway.main_igw
  ]
}

# 3. (OPCIONAL) Se as suas sub-redes públicas ainda não estiverem associadas, 
# utilize este bloco para as associar à Tabela de Rotas pública.
# Este passo é crucial para garantir que as sub-redes onde o Load Balancer vive são 'públicas'.

resource "aws_route_table_association" "public_subnet_association" {
  # 'var.public_subnet_id' deve ser a ID da sua sub-rede pública.
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = var.public_route_table_id
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
    value     = aws_vpc.minha_vpc.id
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = join(",", [
      aws_subnet.public_subnet_a.id,
      aws_subnet.public_subnet_a.id
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
