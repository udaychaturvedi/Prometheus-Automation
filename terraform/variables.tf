variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "vpc_id" {
  type    = string
  default = ""  # if empty, TF will create a VPC
}

variable "public_subnet_ids" {
  type    = list(string)
  default = []  # optional: provide if using existing network
}

variable "allowed_ssh_cidr" {
  type    = string
  default = "49.36.241.165/32"
}

variable "keypair_name" {
  type    = string
  default = "uday-prometheus-key"
}

variable "jenkins_role_name" {
  type    = string
  default = "jenkins-terraform-role"
}

variable "prometheus_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "prometheus_asg_desired_capacity" {
  type    = number
  default = 1
}

variable "create_keypair" {
  type    = bool
  default = true
}

variable "domain_name" {
  type    = string
  default = ""  # set e.g. monitor.example.com to enable Let's Encrypt
}

variable "grafana_separate" {
  type    = bool
  default = false
}

