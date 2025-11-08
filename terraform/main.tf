# Provider
provider "aws" {
  region = "ap-south-1"
}

# Security Group for Prometheus
resource "aws_security_group" "prometheus_sg" {
  name        = "prometheus-sg"
  description = "Allow SSH and Prometheus"

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow Prometheus UI"
    from_port   = 9090
    to_port     = 9090
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

# EC2 instance for Prometheus
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

