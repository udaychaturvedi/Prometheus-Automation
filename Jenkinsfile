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

        stage('Terraform Init & Validate') {
            steps {
                dir('terraform') {
                    sh 'terraform init -reconfigure'
                    sh 'terraform validate'
                }
            }
        }

        stage('User Decision: Apply or Destroy') {
            steps {
                script {
                    def choice = input(
                        id: "ACTION_CHOICE",
                        message: "Choose what you want to do:",
                        parameters: [
                            choice(
                                name: 'ACTION',
                                choices: ['apply', 'destroy'],
                                description: 'Select apply or destroy'
                            )
                        ]
                    )
                    env.ACTION = choice
                    echo "User selected: ${env.ACTION}"
                }
            }
        }

        stage('Terraform Apply or Destroy') {
            steps {
                script {
                    if (env.ACTION == "apply") {
                        dir('terraform') {
                            sh "terraform apply -auto-approve"
                        }
                    } else {
                        dir('terraform') {
                            sh "terraform destroy -auto-approve"
                        }
                        echo "Infrastructure destroyed. Pipeline ending."
                        currentBuild.result = 'SUCCESS'
                        return
                    }
                }
            }
        }

        stage('Fetch Public IP (Only for Apply)') {
            when {
                expression { env.ACTION == "apply" }
            }
            steps {
                script {
                    env.PROM_IP = sh(
                        script: "terraform -chdir=terraform output -raw prometheus_public_ip",
                        returnStdout: true
                    ).trim()

                    echo "Prometheus Public IP: ${env.PROM_IP}"
                }
            }
        }

        stage('Run Ansible (Only for Apply)') {
            when {
                expression { env.ACTION == "apply" }
            }

            steps {
                withCredentials([
                    file(credentialsId: 'ec2-ssh-key-file', variable: 'SSH_KEY')
                ]) {

                    dir('ansible') {
                        sh """
                            ANSIBLE_HOST_KEY_CHECKING=False \
                            ansible-playbook -i inventory_aws_ec2.yml site.yml \
                            --private-key \$SSH_KEY
                        """
                    }
                }
            }
        }

        stage('Final Output (Only for Apply)') {
            when {
                expression { env.ACTION == "apply" }
            }
            steps {
                echo "======================================="
                echo "      Deployment Completed Successfully"
                echo "======================================="
                echo "Prometheus: http://${env.PROM_IP}:9090"
                echo "Grafana:    http://${env.PROM_IP}:3000"
                echo "AlertManager: http://${env.PROM_IP}:9093"
                echo "======================================="
            }
        }
    }

    post {
        success {
            echo "Pipeline executed successfully!"
        }
        failure {
            echo "Pipeline failed!"
        }
    }
}
