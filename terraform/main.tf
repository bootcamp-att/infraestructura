module "network" {
  source      = "./modules/network"
  vpc_cidr    = var.vpc_cidr
  environment = var.environment
}

# Instancias para Bastion Host y Kong
module "compute" {
  source                = "./modules/compute"
  subnet_id             = module.network.public_subnet_id
  bastion_sg_id         = module.network.bastion_sg_id
  kong_sg_id            = module.network.kong_sg_id
  bastion_instance_type = var.bastion_instance_type
  kong_instance_type    = var.kong_instance_type
  environment           = var.environment
}

# Módulo de Kubernetes (1 Master + 4 Workers)
module "k8s" {
  source               = "./modules/k8s"
  subnet_id            = module.network.public_subnet_id
  k8s_sg_id            = module.network.k8s_sg_id
  key_name             = module.compute.key_name
  master_instance_type = "t3.small"
  worker_instance_type = "t3.small"
  worker_count         = 4
  environment          = var.environment
}

# Módulo de Identidad (LLDAP + Authelia)
module "identity" {
  source         = "./modules/identity"
  subnet_id      = module.network.public_subnet_id
  identity_sg_id = module.network.identity_sg_id
  key_name       = module.compute.key_name
  instance_type  = "t3.small"
  environment    = var.environment
}

# Generación del archivo de inventario para Ansible
resource "local_file" "ansible_inventory" {
  filename        = "${path.module}/../ansible/inventory.ini"
  file_permission = "0644"
  content         = <<-EOT
[bastion]
bastion_host ansible_host=${module.compute.bastion_public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=${abspath(module.compute.ssh_key_path)}

[kong]
kong_gateway ansible_host=${module.compute.kong_private_ip} ansible_user=ubuntu ansible_ssh_private_key_file=${abspath(module.compute.ssh_key_path)}

[identity]
identity_server ansible_host=${module.identity.identity_private_ip} ansible_user=ubuntu ansible_ssh_private_key_file=${abspath(module.compute.ssh_key_path)}

[k8s_master]
k8s_master_1 ansible_host=${module.k8s.master_private_ip} ansible_user=ubuntu ansible_ssh_private_key_file=${abspath(module.compute.ssh_key_path)}

[k8s_workers]
%{ for idx, ip in module.k8s.workers_private_ips ~}
k8s_worker_${idx + 1} ansible_host=${ip} ansible_user=ubuntu ansible_ssh_private_key_file=${abspath(module.compute.ssh_key_path)}
%{ endfor ~}

[k8s:children]
k8s_master
k8s_workers

[kong:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand="ssh -W %h:%p -q -i ${abspath(module.compute.ssh_key_path)} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@${module.compute.bastion_public_ip}"'

[identity:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand="ssh -W %h:%p -q -i ${abspath(module.compute.ssh_key_path)} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@${module.compute.bastion_public_ip}"'

[k8s:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand="ssh -W %h:%p -q -i ${abspath(module.compute.ssh_key_path)} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@${module.compute.bastion_public_ip}"'

[all:vars]
ansible_ssh_extra_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
EOT
}