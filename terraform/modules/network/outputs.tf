output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "bastion_sg_id" {
  value = aws_security_group.bastion_sg.id
}

output "kong_sg_id" {
  value = aws_security_group.kong_sg.id
}

output "k8s_sg_id" {
  value = aws_security_group.k8s_sg.id
}

output "identity_sg_id" {
  value = aws_security_group.identity_sg.id
}