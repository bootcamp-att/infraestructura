variable "subnet_id" {
  type        = string
  description = "ID de la Subred Publica"
}

variable "k8s_sg_id" {
  type        = string
  description = "ID del Security Group para el cluster K8s"
}

variable "key_name" {
  type        = string
  description = "Nombre de la clave SSH registrada en AWS"
}

variable "master_instance_type" {
  type        = string
  description = "Tipo de instancia para el Nodo Master"
  default     = "t3.medium" 
}

variable "worker_instance_type" {
  type        = string
  description = "Tipo de instancia para los Nodos Workers"
  default     = "t3.small"
}

variable "worker_count" {
  type        = number
  description = "Numero de nodos Workers"
  default     = 4
}

variable "environment" {
  type        = string
  description = "Entorno de despliegue"
}