pipeline {
    agent any
    stages {
        stage('Terraform Init') {
            steps {
                echo "Initializing Terraform backend..."
                dir('terraform') {
                    sh 'terraform init'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                echo "Planning Terraform changes..."
                dir('terraform') {
                    sh 'terraform plan'
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                echo "Creating EC2 instance..."
                dir('terraform') {
                    sh 'terraform apply -auto-approve'
                }
            }
        }

        stage('Ansible Install') {
            steps {
                echo "Installing Prometheus via Ansible..."
                dir('ansible') {
                    sh 'ansible-playbook -i inventory_aws_ec2.yml prometheus_install.yml'
                }
            }
        }

        stage('Verify') {
            steps {
                echo "Prometheus installation done! UI available at http://<EC2_PUBLIC_IP>:9090"
            }
        }
    }
}
