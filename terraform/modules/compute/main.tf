# Generar par de llaves SSH de forma dinamica
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Guardar la clave privada localmente en tu sistema operativo
resource "local_file" "private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.module}/../../id_rsa_infra_${var.environment}.pem"
  file_permission = "0600"
}

# Registrar la clave publica en AWS
resource "aws_key_pair" "generated_key" {
  key_name   = "key-${var.environment}"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# Obtener la AMI de Ubuntu 24.04 LTS mas reciente
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

# Instancia: Bastion Host
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.bastion_instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.bastion_sg_id]
  key_name               = aws_key_pair.generated_key.key_name

  lifecycle {
    ignore_changes = [ami]
  }

  tags = {
    Name        = "bastion-host-${var.environment}"
    Role        = "Bastion"
    Environment = var.environment
  }
}

# Instancia: Kong API Gateway
resource "aws_instance" "kong" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.kong_instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.kong_sg_id]
  key_name               = aws_key_pair.generated_key.key_name

  lifecycle {
    ignore_changes = [ami]
  }

  tags = {
    Name        = "kong-gateway-${var.environment}"
    Role        = "API-Gateway"
    Environment = var.environment
  }
}

# Crear la Elastic IP para la instancia de Kong
resource "aws_eip" "kong_eip" {
  instance = aws_instance.kong.id
  domain   = "vpc"

  tags = {
    Name        = "eip-kong-${var.environment}"
    Environment = var.environment
  }
}