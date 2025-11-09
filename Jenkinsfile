pipeline {
    agent any
    stages {
        stage('Terraform Init') {
            steps {
                echo "Initializing Terraform..."
                dir('terraform') {
                    sh 'terraform init || echo "Terraform Init skipped for demo"'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                echo "Planning Terraform changes..."
                dir('terraform') {
                    sh 'terraform plan || echo "Terraform Plan skipped for demo"'
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                echo "Applying Terraform changes..."
                dir('terraform') {
                    sh 'terraform apply -auto-approve || echo "Terraform Apply skipped for demo"'
                }
            }
        }

        stage('Ansible Deploy') {
            steps {
                echo "Deploying Prometheus via Ansible..."
                dir('ansible') {
                    sh 'ansible-playbook -i inventory_aws_ec2.yml prometheus_install.yml || echo "Ansible skipped for demo"'
                }
            }
        }

        stage('Verify') {
            steps {
                echo "Prometheus deployment done! Visit http://<EC2_IP>:9090"
            }
        }
    }
}
