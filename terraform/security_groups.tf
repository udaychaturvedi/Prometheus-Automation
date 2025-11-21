resource "aws_security_group" "prometheus_sg" {
  name        = "prometheus-private-sg"
  description = "Prometheus private instance SG"
  vpc_id      = var.vpc_id

  # SSH only from Bastion
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [var.bastion_sg_id]
  }

  # Prometheus 9090
  ingress {
    from_port       = 9090
    to_port         = 9090
    protocol        = "tcp"
    security_groups = [var.bastion_sg_id]
  }

  # Grafana 3000
  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [var.bastion_sg_id]
  }

  # Alertmanager 9093
  ingress {
    from_port       = 9093
    to_port         = 9093
    protocol        = "tcp"
    security_groups = [var.bastion_sg_id]
  }

  # Outgoing
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "prometheus-private-sg"
  }
}

