
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
  vpc_id = aws_vpc.minha_vpc.id

  tags = {
    Name = "igw-para-elasticbeanstalk"
  }
}

# Criação da Route Table
resource "aws_route_table" "public" {
  # O VPC ID é a referência obrigatória à sua Virtual Private Cloud
  # Substitua 'aws_vpc.main.id' pela referência ao seu recurso VPC
  vpc_id = aws_vpc.minha_vpc.id

  tags = {
    Name = "public-route-table"
  }
}

# -------------------------------------------------------------
# Exemplo de Associação da Route Table a uma Sub-rede (Opcional)
# Se quiser que a Route Table criada seja utilizada por uma Sub-rede
# -------------------------------------------------------------

/*
resource "aws_route_table_association" "public_subnet_association" {
  # Substitua 'aws_subnet.public_a.id' pela referência à sua sub-rede
  subnet_id      = aws_subnet.public_a.id
  # Referência à Route Table criada acima
  route_table_id = aws_route_table.public.id
}
*/


# 2. Atualização da Tabela de Rotas Pública
# Adiciona uma rota 0.0.0.0/0 (todo o tráfego) para o Internet Gateway na Tabela de Rotas pública

resource "aws_route" "default_internet_route" {
  # 'var.public_route_table_id' deve ser a referência à sua Tabela de Rotas pública.
  # Se criou a Tabela de Rotas no Terraform, use a referência, ex: aws_route_table.public.id
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main_igw.id
  
  # Adicionar depends_on para garantir que o IGW é criado antes da rota
  depends_on = [
    aws_internet_gateway.main_igw
  ]
}

#  Associar as 2 subnets públicas à Tabela de Rotas pública.
# Isto garante que as subnets onde o Load Balancer vive são 'públicas'

# Associa a Sub-rede A à Tabela de Rotas pública (que tem rota para o IGW)
resource "aws_route_table_association" "public_subnet_a_association" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public.id
}

# Associa a Sub-rede B à Tabela de Rotas pública
resource "aws_route_table_association" "public_subnet_b_association" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public.id
}

# Security Group
resource "aws_security_group" "ec2_instance_security_group" {
  name        = "${var.application_name}-sg"
  description = "Security group for Elastic Beanstalk instances"
  vpc_id      = aws_vpc.minha_vpc.id

  # Regra de Entrada (Ingress) - Tráfego HTTP (porta 80) de qualquer lugar
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Regra de Saída (Egress) - Permite todo o tráfego de saída
  # NECESSÁRIO para a comunicação das instâncias com a API da AWS (Elastic Beanstalk)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 significa todos os protocolos
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.application_name}-Instance-SG"
  }
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
  # Atribui o Security Group às instâncias EC2
  setting {
    namespace = "aws:ec2:vpc"
    name      = "AssociatePublicIpAddress"
    value     = "True"
  }
  
  # Adiciona o Security Group que criamos
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSecurityGroups" # Para o Load Balancer, se houver
    value     = aws_security_group.ec2_instance_security_group.id
  }
  
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups" # Para as instâncias EC2
    value     = aws_security_group.ec2_instance_security_group.id
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
