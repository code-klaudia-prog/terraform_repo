# Configuração do Providor AWS
provider "aws" {
  region = var.aws_region
}

# Configuração do Providor TFE
terraform {
  required_version = ">= 0.12"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0.0"
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Criacao VPC, Subnets e NAT Gateways
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  # Usa variáveis de input
  name = var.project_name
  cidr = var.vpc_cidr

  # Multiple AZ Distribution
  azs               = slice(data.aws_availability_zones.available.names, 0, 2)
  
  # CIDRs for Subnets (usa variáveis de input)
  public_subnets  = var.public_subnet_cidrs
  private_subnets = var.private_subnet_cidrs

  # Gateways Configuration
  enable_nat_gateway      = true    
  single_nat_gateway      = false
  enable_dns_hostnames    = true
  enable_dns_support      = true
}

# Deployment do Security Group do Bastion Host (associado a VPC)
resource "aws_security_group" "bastion_host_sg_cesae" {
  name        = "${var.project_name}-bastion-sg"
  description = "Bastion host SG"
  vpc_id      = module.vpc.vpc_id

  # SSH Access (Port 22) - Agora usa a variável de input ssh_allowed_cidr
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr] 
    description = "Allow SSH from variable CIDR"
  }

  # ICMP for Ping
  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow ICMP (Ping) from the Internet"
  }

  # Outbound Rule - Permite todo o tráfego de saída
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic to the Internet"
  }
}

# Deployment do Bastion Host na subrede publica
resource "aws_instance" "bastion_host_cesae" {
  # Usa variáveis de input
  ami           = var.ami_id
  instance_type = var.bastion_instance_type
  
  # Associação à primeira sub-rede pública criada pelo módulo VPC
  subnet_id = module.vpc.public_subnets[0]
  
  # Associação do Bastion Host ao Security Group
  vpc_security_group_ids = [aws_security_group.bastion_host_sg_cesae.id] 
  
  associate_public_ip_address = true 
}

# Criacao do Security Group da instancia EC2 instance (associado a VPC)
resource "aws_security_group" "private_instance_sg_cesae" {
  name        = "${var.project_name}-private-instance-sg"
  description = "Security group for private instance"
  vpc_id      = module.vpc.vpc_id

  # Inbound Rule - Allows SSH from within VPC CIDR
  ingress {
    description = "Allow SSH from within VPC CIDR"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  # Outbound Rule - Permite todo o tráfego de saída
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Deployent da instancia EC2 na subrede privada
resource "aws_instance" "ec2_prinvate_instance" {
  # Usa variáveis de input
  ami           = var.ami_id
  instance_type = var.private_instance_type
  
  # Associação à primeira sub-rede privada criada pelo módulo VPC
  subnet_id      = module.vpc.private_subnets[0]

  # Associação ao Security Group
  vpc_security_group_ids      = [aws_security_group.private_instance_sg_cesae.id] 
  associate_public_ip_address = false # Instância privada
}

# O resto dos blocos comentados foram mantidos como estavam.
