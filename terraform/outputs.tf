output "prometheus_asg_name" {
  value = aws_autoscaling_group.prometheus_asg.name
}

output "keypair_private_pem" {
  value     = try(tls_private_key.key[0].private_key_pem, null)
  sensitive = true
}

