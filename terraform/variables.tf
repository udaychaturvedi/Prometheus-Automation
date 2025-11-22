variable "vpc_id" {
  default = "vpc-0f7579fbae6a6f354"
}

# Choose one good subnet (ap-south-1a)
variable "prom_subnet_id" {
  default = "subnet-01b8c679a5d46851f"
}

variable "keypair_name" {
  default = "new-uday-key"
}

variable "bastion_sg_id" {
  default = "sg-00726f2d984a60667"
}

