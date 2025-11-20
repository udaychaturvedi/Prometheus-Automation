# Provider
provider "aws" {
  region = "ap-south-1"
}

# Security Group for Prometheus + Grafana
resource "aws_security_group" "prometheus_sg" {
  name        = "prometheus-sg"
  description = "Allow Prometheus, Alertmanager, Node Exporter, Grafana, SSH"

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Prometheus UI"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Grafana UI"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Node Exporter"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Alertmanager"
    from_port   = 9093
    to_port     = 9093
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
    Name = "prometheus-sg"
  }
}

# EC2 instance for Prometheus + Grafana
resource "aws_instance" "prometheus_server" {
  ami           = "ami-087d1c9a513324697"
  instance_type = "t2.micro"
  key_name      = "new-uday-key"
  vpc_security_group_ids = [aws_security_group.prometheus_sg.id]

  tags = {
    Name = "Prometheus-Server"
  }
}

# Output public IP
output "prometheus_public_ip" {
  value = aws_instance.prometheus_server.public_ip
}

