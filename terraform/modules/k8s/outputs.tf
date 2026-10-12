output "master_private_ip" {
  value = aws_instance.k8s_master.private_ip
}

output "workers_private_ips" {
  value = aws_instance.k8s_workers[*].private_ip
}
