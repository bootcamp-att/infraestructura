output "bastion_public_ip" {
  description = "IP publica del Bastion Host (para conexion SSH inicial)"
  value       = module.compute.bastion_public_ip
}

output "kong_public_ip" {
  description = "IP publica de la instancia Kong (para trafico HTTP/HTTPS)"
  value       = module.compute.kong_public_ip
}

output "kong_private_ip" {
  description = "IP privada de la instancia Kong (para gestion mediante Ansible a traves del Bastion)"
  value       = module.compute.kong_private_ip
}

output "private_key_file" {
  description = "Ruta de la clave privada SSH generada"
  value       = module.compute.ssh_key_path
}