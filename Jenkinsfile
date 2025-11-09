pipeline {
    agent any

    environment {
        AWS_ACCESS_KEY_ID = credentials('aws-access-key')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key')
        AWS_DEFAULT_REGION = 'ap-south-1'
    }

    stages {
        stage('Clean Workspace') {
            steps {
                echo "Cleaning workspace before start"
                deleteDir()
            }
        }

        stage('Checkout') {
            steps {
                echo "Getting code from GitHub"
                git credentialsId: 'github-creds', url: 'https://github.com/udaychaturvedi/prometheus-automation.git'
            }
        }

        stage('Terraform Init & Apply') {
            steps {
                dir('terraform') {
                    echo "Init Terraform"
                    sh 'terraform init -reconfigure'
                    
                    echo "Apply Terraform"
                    sh 'terraform apply -auto-approve'
                }
            }
        }

        stage('Generate Dynamic Inventory') {
            steps {
                dir('ansible') {
                    script {
                        // Get EC2 public IP from Terraform output
                        def ip = sh(script: "terraform output -raw prometheus_public_ip", returnStdout: true).trim()

                        // Create inventory file dynamically
                        writeFile file: 'inventory_aws_ec2.yml', text: """
all:
  hosts:
    prometheus_server:
      ansible_host: ${ip}
      ansible_user: ubuntu
      ansible_ssh_private_key_file: /var/lib/jenkins/.ssh/new-uday-key.pem
"""
                        echo "Inventory created with dynamic IP: ${ip}"
                    }
                }
            }
        }

        stage('Deploy Prometheus') {
            steps {
                dir('ansible') {
                    echo "Running Ansible playbook"
                    sh 'ansible-playbook -i inventory_aws_ec2.yml prometheus_install.yml --ssh-extra-args="-o StrictHostKeyChecking=no"'
                }
            }
        }

        stage('Verify') {
            steps {
                echo "Deployment done! Visit http://${terraform output -raw prometheus_public_ip}:9090"
            }
        }
    }
}
