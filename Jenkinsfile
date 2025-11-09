pipeline {
    agent any
    environment {
        AWS_ACCESS_KEY_ID     = credentials('aws-creds')
        AWS_SECRET_ACCESS_KEY = credentials('aws-creds')
    }
    stages {
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
    }
}
