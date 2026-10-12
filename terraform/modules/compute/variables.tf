variable "subnet_id" {
  type        = string
  description = "ID de la Subred"
}

variable "bastion_sg_id" {
  type        = string
  description = "ID del Security Group para Bastion"
}

variable "kong_sg_id" {
  type        = string
  description = "ID del Security Group para Kong"
}

variable "bastion_instance_type" {
  type        = string
  description = "Tipo de instancia del Bastion Host"
}

variable "kong_instance_type" {
  type        = string
  description = "Tipo de instancia de Kong API Gateway"
}

variable "environment" {
  type        = string
  description = "Nombre del entorno"
}