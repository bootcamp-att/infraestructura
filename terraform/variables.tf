variable "aws_region" {
  type        = string
  description = "Región de AWS"
  default     = "us-east-1"
}

variable "aws_profile" {
  type        = string
  description = "Perfil de AWS CLI configurado para la empresa"
  default     = "empresa-terraform"
}

variable "environment" {
  type        = string
  description = "Nombre del entorno"
  default     = "dev"
}

variable "vpc_cidr" {
  type        = string
  description = "Bloque CIDR para la VPC"
  default     = "10.0.0.0/16"
}

variable "bastion_instance_type" {
  type        = string
  description = "Tipo de instancia para el Bastion Host"
  default     = "t3.micro"
}

variable "kong_instance_type" {
  type        = string
  description = "Tipo de instancia para Kong API Gateway"
  default     = "t3.small"
}