resource "aws_launch_template" "prometheus_lt" {
  name_prefix   = "prometheus-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.prometheus_instance_type

  key_name = var.create_keypair ? aws_key_pair.generated[0].key_name : var.keypair_name

  vpc_security_group_ids = [ aws_security_group.prometheus_sg.id ]

  user_data = base64encode(<<-EOF
#!/bin/bash
apt-get update -y
apt-get install -y docker.io

systemctl enable docker
systemctl start docker

# Prometheus, Alertmanager, Grafana, Node Exporter will be installed by Ansible
EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "prometheus-asg-instance"
    }
  }
}

resource "aws_autoscaling_group" "prometheus_asg" {
  name                    = "prometheus-asg"
  desired_capacity        = var.prometheus_asg_desired_capacity
  max_size                = 3
  min_size                = 1

  # ternary must be a single expression (do NOT split lines awkwardly)
  vpc_zone_identifier = local.create_vpc ? [aws_subnet.public[0].id] : var.public_subnet_ids

  launch_template {
    id      = aws_launch_template.prometheus_lt.id
    version = "$Latest"
  }

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "prometheus-asg-instance"
    propagate_at_launch = true
  }
}

