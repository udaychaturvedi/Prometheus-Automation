pipeline {
    agent any
    stages {
        stage('Clean Workspace') {
            steps {
                deleteDir()
            }
        }

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws-creds', 
                                  usernameVariable: 'AWS_ACCESS_KEY_ID', 
                                  passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    dir('terraform') {
                        sh 'terraform init -reconfigure'
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws-creds', 
                                  usernameVariable: 'AWS_ACCESS_KEY_ID', 
                                  passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    dir('terraform') {
                        sh 'terraform plan'
                    }
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws-creds', 
                                  usernameVariable: 'AWS_ACCESS_KEY_ID', 
                                  passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    dir('terraform') {
                        sh 'terraform apply -auto-approve'
                    }
                }
            }
        }

        stage('Ansible Deploy') {
    steps {
        withCredentials([usernamePassword(credentialsId: 'aws-creds',
                                         usernameVariable: 'AWS_ACCESS_KEY_ID',
                                         passwordVariable: 'AWS_SECRET_ACCESS_KEY'),
                         file(credentialsId: 'ssh-key', variable: 'SSH_KEY')]) {
            dir('ansible') {
                script {
                    def prometheus_ip = sh(
                        script: "terraform -chdir=../terraform output -raw prometheus_public_ip",
                        returnStdout: true
                    ).trim()
                    sh "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory_aws_ec2.yml prometheus_install.yml -e prometheus_ip=${prometheus_ip} --private-key \$SSH_KEY"
                }
            }
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




