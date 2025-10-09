
# Configuração do Providor AWS
provider "aws" {
  region = "us-east-1" 
}

# Configuração do Providor TFE (Interage com a TF Cloud API)
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
  version = "~> 5.0" # Use a versão mais recente e estável

  # VPC CIDR Block
  name = "cesae-final-project"
  cidr = "10.0.0.0/16"

  # Multiple AZ Distribution
  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  
  # CIDRs for Public Subnets
  public_subnets  = ["10.0.1.0/24", "10.0.3.0/24"]
  
  # CIDRs for Private Subnets
  private_subnets = ["10.0.2.0/24", "10.0.4.0/24"]

  # Gateways Configuration
  enable_nat_gateway     = true  
  single_nat_gateway     = false
  enable_dns_hostnames   = true
  enable_dns_support     = true
}

# Deployment do Security Group do Bastion Host (associado a VPC)
resource "aws_security_group" "bastion_host_sg_cesae" {
  name        = "private-instance-sg"
  description = "Bastion host SG"
  vpc_id      = module.vpc.vpc_id

  # Inbound Rule - Allows all SSH conections from the outside (from the Internet Gateway)
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound Rule is not needed because, by default, it allows all traffic to leave 
}

# Deployment do Bastion Host na subrede publica
resource "aws_instance" "bastion_host_cesae" {
  ami           = "ami-052064a798f08f0d3"
  instance_type = "t3.micro"
  
  # Associação à sub-rede publica "10.0.3.0/24" denominada de "vpc-avancada-tf-public-us-east-1a"
  subnet_id = "subnet-02d4a2b3dcd6f3461" # PESSIMA IDEIA TER O ID DA SUBNET HARDCODED!!!!
  
  # Associação do Bastion Host ao Security Group
  vpc_security_group_ids = [aws_security_group.bastion_host_sg_cesae.id] 
  
  # Como é um Bastion Host numa sub-rede pública, deve ter um IP público associado
  associate_public_ip_address = true 
}

# Criacao do Security Group da instancia EC2 instance (associado a VPC)
resource "aws_security_group" "private_instance_sg_cesae" {
  name        = "private_instance__sg_cesae"
  description = "Security group for private instance"
  vpc_id      = module.vpc.vpc_id

  # Inbound Rule - Allows SSH conection from the outside into the VPC through the Bastion Host
  ingress {
    description = "Allow SSH from within VPC CIDR"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # Allows SSH acces by any resource within the VPC (10.0.0.0/16)
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  # Outbound Rule -This is what allows the NAT Gateway test
  # It allows all outbound traffic (routed trhough the NAT Gateway)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Deployent da instancia EC2 na subrede privada
resource "aws_instance" "ec2_prinvate_instance" {
  ami           = "ami-052064a798f08f0d3"                         # AMI válido e North Virginia
  instance_type = "t3.micro"  
  # key_name    = aws_key_pair.deployer.key_name

  # Associação à sub-rede
  subnet_id     = "subnet-0992a72db930293a9" 

  # Associação ao Security Group
  vpc_security_group_ids = [aws_security_group.private_instance_sg_cesae.id]   
  # Desligaria a atribuição automática de IP público (característica da subnet privada). Isto se o TF Cloud nao estivesse a dar erro
  # associate_public_ip_address = true 
}

# Create an Internet Gateway (IGW)
# resource "aws_internet_gateway" "cesae_internet_gw" {
#  vpc_id      = module.vpc.vpc_id
#}

resource "aws_route_table" "route_table_cesae" {
  vpc_id = module.vpc.vpc_id
}

# Associação da Route Table a uma Sub-rede
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = "subnet-02d4a2b3dcd6f3461"
  route_table_id = aws_route_table.route_table_cesae.id
}

# Atualização da Tabela de Rotas Pública
# Adiciona uma rota 0.0.0.0/0 (todo o tráfego) para o Internet Gateway na Tabela de Rotas pública

resource "aws_route" "routes" {
  route_table_id         = aws_route_table.route_table_cesae.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "igw-07d62f391cdecdcc3"
  
  # depends_on = [
  #  aws_internet_gateway.main_igw
  # ]
}


# Nao fora usados key-pairs de acesso a nehua das instancias
# resource "aws_key_pair" "deployer" {
#  key_name   = "private-instance-key"
#  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC4" # Replace
#}
