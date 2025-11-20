pipeline {

    agent any

    stages {

        stage('Clean Workspace') {
            steps {
                deleteDir()
            }
        }

        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/udaychaturvedi/Prometheus-Automation.git'
            }
        }

        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    sh 'terraform init -reconfigure'
                }
            }
        }

        stage('Choose Action') {
            steps {
                script {
                    ACTION = input(
                        id: "userInput",
                        message: "Choose Terraform Action",
                        parameters: [
                            choice(name: 'Action', choices: ['apply', 'destroy'])
                        ]
                    )
                    echo "User selected: ${ACTION}"
                }
            }
        }

        stage('Terraform Apply') {
            when { expression { ACTION == "apply" } }
            steps {
                dir('terraform') {
                    sh 'terraform apply -auto-approve'
                }
            }
        }

        stage('Terraform Destroy') {
            when { expression { ACTION == "destroy" } }
            steps {
                dir('terraform') {
                    sh 'terraform destroy -auto-approve'
                }
            }
        }

        stage('Get Public IP') {
            when { expression { ACTION == "apply" } }
            steps {
                script {
                    PUBLIC_IP = sh(
                        script: "terraform -chdir=terraform output -raw prometheus_public_ip",
                        returnStdout: true
                    ).trim()

                    echo "Prometheus Public IP = ${PUBLIC_IP}"
                }
            }
        }

        stage('Run Ansible Deployment') {
            when { expression { ACTION == "apply" } }

            steps {
                withCredentials([file(credentialsId: 'ec2-ssh-key-file', variable: 'SSH_KEY')]) {

                    dir('ansible') {
                        sh """
                            ANSIBLE_HOST_KEY_CHECKING=False \
                            ansible-playbook -i inventory_aws_ec2.yml site.yml --private-key \$SSH_KEY
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            script {
                if (ACTION == "apply") {
                    echo "=============================================="
                    echo " PROMETHEUS, ALERTMANAGER & GRAFANA LINKS"
                    echo "=============================================="
                    echo "Prometheus   : http://${PUBLIC_IP}:9090"
                    echo "Alertmanager : http://${PUBLIC_IP}:9093"
                    echo "Grafana      : http://${PUBLIC_IP}:3000"
                    echo "=============================================="
                } else {
                    echo "Infrastructure Destroyed Successfully!"
                }
            }
        }
        failure {
            echo "Pipeline failed! Check logs."
        }
    }
}
