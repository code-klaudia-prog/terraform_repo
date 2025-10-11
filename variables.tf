variable "aws_region" {
  description = "A região AWS onde os recursos serão criados."
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "O ID da AMI para as instâncias EC2."
  type        = string
  default     = "ami-052064a798f08f0d3" # AMI válido em us-east-1
}

variable "project_name" {
  description = "Nome base para a VPC e outros recursos."
  type        = string
  default     = "cesae-final-project"
}

variable "vpc_cidr" {
  description = "Bloco CIDR para a VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Lista de blocos CIDR para as sub-redes públicas."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Lista de blocos CIDR para as sub-redes privadas."
  type        = list(string)
  default     = ["10.0.2.0/24", "10.0.4.0/24"]
}

variable "bastion_instance_type" {
  description = "Tipo de instância EC2 para o Bastion Host."
  type        = string
  default     = "t3.micro"
}

variable "private_instance_type" {
  description = "Tipo de instância EC2 para a Instância Privada."
  type        = string
  default     = "t3.micro"
}

variable "ssh_allowed_cidr" {
  description = "Bloco CIDR que pode aceder por SSH (Porta 22) ao Bastion Host."
  type        = string
  default     = "0.0.0.0/0" # ATENÇÃO: Mudar para o seu IP específico para maior segurança!
}
