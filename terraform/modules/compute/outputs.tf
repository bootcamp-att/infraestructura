output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "kong_public_ip" {
  description = "IP publica estatica (Elastic IP) asignada a Kong"
  value       = aws_eip.kong_eip.public_ip
}

output "kong_private_ip" {
  value = aws_instance.kong.private_ip
}

output "ssh_key_path" {
  value = local_file.private_key.filename
}

output "key_name" {
  value = aws_key_pair.generated_key.key_name
}