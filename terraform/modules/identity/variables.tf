variable "subnet_id" {
  type        = string
  description = "ID de la Subred Publica"
}

variable "identity_sg_id" {
  type        = string
  description = "ID del Security Group para el servidor de Identidad"
}

variable "key_name" {
  type        = string
  description = "Nombre de la clave SSH registrada en AWS"
}

variable "instance_type" {
  type        = string
  description = "Tipo de instancia EC2"
  default     = "t3.small"
}

variable "environment" {
  type        = string
  description = "Entorno de despliegue"
}