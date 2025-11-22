output "keypair_private_pem" {
  value     = tls_private_key.key[0].private_key_pem
  sensitive = true
}

