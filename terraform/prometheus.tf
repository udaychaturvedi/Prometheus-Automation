resource "aws_instance" "prometheus" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3a.medium"
  subnet_id                   = var.prom_subnet_id
  key_name                    = var.keypair_name
  vpc_security_group_ids      = [aws_security_group.prometheus_sg.id]
  associate_public_ip_address = false

  tags = {
    Name = "prometheus-private"
    Role = "prometheus"
  }
}

