variable "vpc_id" {
  default = "vpc-08cc8c38267b017a6"
}

variable "prom_subnet_id" {
  default = "subnet-0925533e16526bc0a"
}

variable "keypair_name" {
  default = "new-uday-key"
}

# Bastion SG permanent
variable "bastion_sg_id" {
  default = "sg-00726f2d984a60667"
}

