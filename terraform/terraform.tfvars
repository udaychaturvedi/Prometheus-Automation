region                     = "ap-south-1"
allowed_ssh_cidr           = "49.36.241.165/32"
keypair_name               = "uday-prometheus-key"
create_keypair             = true
prometheus_instance_type   = "t3.medium"
prometheus_asg_desired_capacity = 1
domain_name                = ""  # set if you have a domain
grafana_separate           = false
prometheus_instance_type   = "t2.micro"

