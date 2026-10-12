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

# Instancia EC2 dedicada para LLDAP + Authelia
resource "aws_instance" "identity" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.identity_sg_id]
  key_name               = var.key_name

  lifecycle {
    ignore_changes = [ami]
  }

  tags = {
    Name        = "identity-server-${var.environment}"
    Role        = "Identity-Provider"
    Environment = var.environment
  }
}