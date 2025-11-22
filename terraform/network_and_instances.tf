locals {
  create_vpc = var.vpc_id == "" ? true : false
}

resource "aws_vpc" "this" {
  count      = local.create_vpc ? 1 : 0
  cidr_block = "10.20.0.0/16"

  tags = {
    Name = "uday-prometheus-vpc"
  }
}

resource "aws_internet_gateway" "gw" {
  count  = local.create_vpc ? 1 : 0
  vpc_id = aws_vpc.this[0].id

  tags = { Name = "uday-prometheus-igw" }
}

resource "aws_subnet" "public" {
  count             = local.create_vpc ? 2 : length(var.public_subnet_ids)
  vpc_id            = local.create_vpc ? aws_vpc.this[0].id : var.vpc_id
  cidr_block        = local.create_vpc ? cidrsubnet(aws_vpc.this[0].cidr_block, 8, count.index) : ""
  availability_zone = local.create_vpc ? element(["ap-south-1a","ap-south-1b"], count.index) : null
  map_public_ip_on_launch = true

  tags = {
    Name = "uday-prometheus-public-subnet-${count.index}"
  }

  lifecycle {
    ignore_changes = [availability_zone]
  }
}

resource "aws_route_table" "public" {
  count  = local.create_vpc ? 1 : 0
  vpc_id = local.create_vpc ? aws_vpc.this[0].id : var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw[0].id
  }

  tags = { Name = "uday-prometheus-public-rt" }
}

resource "aws_route_table_association" "a" {
  count          = local.create_vpc ? length(aws_subnet.public) : 0
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

# Security groups
resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Allow SSH from your IP and web to proxy"
  vpc_id      = local.create_vpc ? aws_vpc.this[0].id : var.vpc_id

  ingress {
    description = "SSH from your IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = length(regexall(":", var.allowed_ssh_cidr)) == 0 ? [var.allowed_ssh_cidr] : []
    ipv6_cidr_blocks = length(regexall(":", var.allowed_ssh_cidr)) > 0 ? [var.allowed_ssh_cidr] : []
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "bastion-sg" }
}

resource "aws_security_group" "prometheus_sg" {
  name        = "prometheus-sg"
  description = "Prometheus/Grafana internal"
  vpc_id      = local.create_vpc ? aws_vpc.this[0].id : var.vpc_id

  ingress {
    from_port       = 9090
    to_port         = 9090
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
    description     = "Prometheus from bastion/nginx"
  }

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
    description     = "Grafana from bastion/nginx"
  }

  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["10.20.0.0/16"]
    description = "node_exporter internal"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "prometheus-sg" }
}

# Keypair
resource "tls_private_key" "key" {
  count      = var.create_keypair ? 1 : 0
  algorithm  = "RSA"
  rsa_bits   = 4096
}

resource "aws_key_pair" "generated" {
  count      = var.create_keypair ? 1 : 0
  key_name   = var.keypair_name
  public_key = tls_private_key.key[0].public_key_openssh
}

# Bastion instance
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  subnet_id                   = local.create_vpc ? aws_subnet.public[0].id : element(var.public_subnet_ids, 0)
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true
  key_name                    = var.create_keypair ? aws_key_pair.generated[0].key_name : var.keypair_name
  tags = { Name = "uday-prometheus-bastion" }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y nginx certbot python3-certbot-nginx
              systemctl enable nginx
              systemctl start nginx
              EOF
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

# Optional: outputs will capture bastion public ip for use by Jenkins/Ansible
output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "bastion_public_dns" {
  value = aws_instance.bastion.public_dns
}

