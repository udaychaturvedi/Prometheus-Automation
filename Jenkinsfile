pipeline {
    agent any

    environment {
        AWS_ACCESS_KEY_ID     = credentials('aws-creds')
        AWS_SECRET_ACCESS_KEY = credentials('aws-creds-secret')
        AWS_DEFAULT_REGION    = 'ap-south-1'
    }

    stages {

        stage('Clean Workspace') {
            steps {
                echo "Cleaning up workspace..."
                deleteDir()
            }
        }

        stage('Checkout Code') {
            steps {
                echo "Getting latest code from GitHub..."
                checkout([$class: 'GitSCM', 
                    branches: [[name: '*/main']], 
                    userRemoteConfigs: [[
                        url: 'https://github.com/udaychaturvedi/prometheus-automation.git', 
                        credentialsId: 'github-creds'
                    ]]
                ])
            }
        }

        stage('Terraform Init') {
            steps {
                echo "Initializing Terraform..."
                dir('terraform') {
                    sh 'terraform init -reconfigure'
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
                echo "Applying Terraform changes..."
                dir('terraform') {
                    sh 'terraform apply -auto-approve'
                }
            }
        }

        stage('Ansible Deploy') {
            steps {
                echo "Deploying Prometheus using Ansible..."
                dir('ansible') {
                    sh 'ansible-playbook -i inventory_aws_ec2.yml prometheus_install.yml'
                }
            }
        }

        stage('Verify') {
            steps {
                echo "Check your Prometheus at http://<EC2_IP>:9090"
            }
        }
    }
}
