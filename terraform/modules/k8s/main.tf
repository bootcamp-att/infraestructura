data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Instancia: K8s Master Node
resource "aws_instance" "k8s_master" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.master_instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.k8s_sg_id]
  key_name               = var.key_name

  # Agrandar el disco de la raíz de 8GB a 30GB gp3
  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
  }

  lifecycle {
    ignore_changes = [ami]
  }

  tags = {
    Name        = "k8s-master-${var.environment}"
    Role        = "k8s-master"
    Environment = var.environment
  }
}

# Instancias: K8s Worker Nodes (4 nodos)
resource "aws_instance" "k8s_workers" {
  count                  = var.worker_count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.worker_instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.k8s_sg_id]
  key_name               = var.key_name

  # Agrandar el disco de la raíz de 8GB a 30GB gp3
  root_block_device {
    volume_size           = 60
    volume_type           = "gp3"
    delete_on_termination = true
  }

  lifecycle {
    ignore_changes = [ami]
  }

  tags = {
    Name        = "k8s-worker-${count.index + 1}-${var.environment}"
    Role        = "k8s-worker"
    Environment = var.environment
  }
}