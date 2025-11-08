Prometheus automation
- terraform/: Terraform code to provision EC2, security group, IAM role
- ansible/: Ansible playbook + dynamic inventory to install Prometheus
- Jenkinsfile: Pipeline to run Terraform then Ansible
