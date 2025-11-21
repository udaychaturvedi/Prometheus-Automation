pipeline {
    agent any

   environment {
    TF_DIR = "terraform"
        }


    stages {

        stage('Clean Workspace') {
            steps { deleteDir() }
        }

        stage('Checkout Repo') {
            steps {
                git(
                    url: 'https://github.com/udaychaturvedi/Prometheus-Automation.git',
                    branch: 'main',
                    credentialsId: 'github-creds'
                )
            }
        }

        stage('Terraform Init') {
            steps {
                dir(env.TF_DIR) {
                    sh 'terraform init -reconfigure'
                }
            }
        }

        stage('Choose Action') {
            steps {
                script {
                    env.ACTION = input message: "Choose Action",
                    parameters: [choice(name: 'ACTION', choices: ['apply','destroy'], description: '')]

                    echo "Selected: ${env.ACTION}"
                }
            }
        }

        stage('Terraform Apply') {
            when { expression { env.ACTION == "apply" } }
            steps {
                dir(env.TF_DIR) {
                    sh "terraform apply -auto-approve"
                }
            }
        }

        stage('Terraform Destroy') {
            when { expression { env.ACTION == "destroy" } }
            steps {
                dir(env.TF_DIR) {
                    sh "terraform destroy -auto-approve"
                }
            }
        }

        stage('Get Public IP') {
            when { expression { env.ACTION == 'apply' } }
            steps {
                script {
                    env.PUB_IP = sh(
                        script: "terraform -chdir=${env.TF_DIR} output -raw jenkins_public_ip",
                        returnStdout: true
                    ).trim()

                    echo "EC2 Public IP: ${env.PUB_IP}"
                }
            }
        }

        stage('Run Ansible') {
            when { expression { env.ACTION == 'apply' } }
            steps {
                withCredentials([file(credentialsId: 'new-uday-key', variable: 'SSH_KEY')]) {
                    dir('ansible') {
                        sh """
                            echo "[prometheus]" > inventory.ini
                            echo "${PUB_IP}" >> inventory.ini

                            chmod 600 \$SSH_KEY
                            export ANSIBLE_HOST_KEY_CHECKING=False

                            ansible-playbook -i inventory.ini site.yml --private-key=\$SSH_KEY -u ubuntu
                        """
                    }
                }
            }
        }

        stage('Show URLs') {
            when { expression { env.ACTION == 'apply' } }
            steps {
                echo "Prometheus   : http://${env.PUB_IP}:9090"
                echo "Alertmanager : http://${env.PUB_IP}:9093"
                echo "Grafana      : http://${env.PUB_IP}:3000"
            }
        }
    }

    post {
        success { echo "Pipeline Completed Successfully!" }
        failure { echo "Pipeline Failed! Check logs." }
    }
}

