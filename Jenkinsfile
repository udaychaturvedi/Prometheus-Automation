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
        dir('ansible') {
            withCredentials([usernamePassword(credentialsId: 'aws-creds',
                              usernameVariable: 'AWS_ACCESS_KEY_ID',
                              passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                script {
                    // get EC2 IP from Terraform output
                    def prometheus_ip = sh(
                        script: "terraform -chdir=../terraform output -raw prometheus_public_ip", 
                        returnStdout: true
                    ).trim()

                    // add host key dynamically
                    sh "ssh-keyscan -H ${prometheus_ip} >> ~/.ssh/known_hosts"

                    // run ansible with dynamic IP
                    sh "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory_aws_ec2.yml prometheus_install.yml -e prometheus_ip=${prometheus_ip}"
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


