output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "bastion_public_dns" {
  value = aws_instance.bastion.public_dns
}

output "prometheus_asg_name" {
  value = aws_autoscaling_group.prometheus_asg.name
}

output "keypair_private_pem" {
  value     = tls_private_key.key[0].private_key_pem
  sensitive = true
  condition = var.create_keypair
}

