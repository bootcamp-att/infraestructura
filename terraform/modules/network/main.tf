resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "vpc-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "igw-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 1)
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_region.current.name}a"

  tags = {
    Name        = "subnet-public-${var.environment}"
    Environment = var.environment
  }
}

data "aws_region" "current" {}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name        = "rt-public-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group: Bastion Host (SSH desde cualquier origen)
resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg-${var.environment}"
  description = "Permite acceso SSH al Bastion Host desde cualquier lugar"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH de cualquier origen"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "bastion-sg-${var.environment}"
    Environment = var.environment
  }
}

# Security Group: Kong API Gateway (HTTP/HTTPS públicos + SSH restringido al Bastion)
resource "aws_security_group" "kong_sg" {
  name        = "kong-sg-${var.environment}"
  description = "Permite trafico HTTP/HTTPS publico y SSH solo desde Bastion Host"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP publico"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS publico"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description     = "SSH unicamente desde Bastion Host"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "kong-sg-${var.environment}"
    Environment = var.environment
  }
}

# Security Group: Clúster K8s (Master + Workers)
resource "aws_security_group" "k8s_sg" {
  name        = "k8s-sg-${var.environment}"
  description = "Permite acceso a K8s solo desde Kong Gateway y SSH desde Bastion"
  vpc_id      = aws_vpc.main.id

  # SSH unicamente desde el Bastion Host
  ingress {
    description     = "SSH desde Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  # Comunicacion entre nodos del cluster K8s
  ingress {
    description = "Trafico interno entre nodos K8s"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  # Ingress / APIs de K8s expuestos solo a Kong API Gateway
  ingress {
    description     = "HTTP/HTTPS/NodePorts desde Kong Gateway"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.kong_sg.id]
  }

  ingress {
    description     = "HTTPS Ingress desde Kong Gateway"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.kong_sg.id]
  }

  ingress {
    description     = "Rango NodePort de K8s desde Kong Gateway"
    from_port       = 30000
    to_port         = 32767
    protocol        = "tcp"
    security_groups = [aws_security_group.kong_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "k8s-sg-${var.environment}"
    Environment = var.environment
  }
}

# Security Group: Identity Server (LLDAP + Authelia)
resource "aws_security_group" "identity_sg" {
  name        = "identity-sg-${var.environment}"
  description = "Permite acceso a Authelia/LLDAP solo desde Kong Gateway y SSH desde Bastion"
  vpc_id      = aws_vpc.main.id

  # SSH únicamente desde el Bastion Host
  ingress {
    description     = "SSH desde Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  # Authelia Portal/API (Puerto 9091) accesible únicamente desde Kong API Gateway
  ingress {
    description     = "Authelia HTTP desde Kong Gateway"
    from_port       = 9091
    to_port         = 9091
    protocol        = "tcp"
    security_groups = [aws_security_group.kong_sg.id]
  }

  # LLDAP Web Admin (Puerto 1717) / LDAP (Puerto 389) accesible desde Kong o red interna
  ingress {
    description     = "LLDAP Web/LDAP desde Kong Gateway"
    from_port       = 1717
    to_port         = 1717
    protocol        = "tcp"
    security_groups = [aws_security_group.kong_sg.id]
  }

  ingress {
    description     = "LLDAP LDAP Port desde la VPC"
    from_port       = 389
    to_port         = 389
    protocol        = "tcp"
    cidr_blocks     = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "identity-sg-${var.environment}"
    Environment = var.environment
  }
}