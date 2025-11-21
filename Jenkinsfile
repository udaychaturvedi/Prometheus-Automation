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
                    env.ACTION = input(
                        message: "Choose Action",
                        parameters: [choice(name: 'ACTION', choices: ['apply','destroy'])]
                    )
                }
            }
        }

        stage('Terraform Apply') {
            when { expression { env.ACTION == "apply" } }
            steps {
                dir(env.TF_DIR) {
                    sh 'terraform apply -auto-approve -lock=false'
                }
            }
        }

        stage('Get Bastion + Private IPs') {
            when { expression { env.ACTION == "apply" } }
            steps {
                script {
                    env.BASTION_IP = sh(
                        script: "terraform -chdir=${env.TF_DIR} output -raw bastion_public_ip",
                        returnStdout: true
                    ).trim()

                    env.PRIVATE_IP = sh(
                        script: "terraform -chdir=${env.TF_DIR} output -raw prometheus_private_ip",
                        returnStdout: true
                    ).trim()

                    echo "Bastion IP      = ${env.BASTION_IP}"
                    echo "Private IP      = ${env.PRIVATE_IP}"
                }
            }
        }

        stage('Run Ansible') {
            when { expression { env.ACTION == 'apply' } }
            steps {
                withCredentials([file(credentialsId: 'new-uday-key', variable: 'SSH_KEY')]) {

                    dir('ansible') {
                        sh '''
                            echo "[prometheus]" > inventory.ini
                            echo "${PRIVATE_IP}" >> inventory.ini

                            chmod 600 $SSH_KEY
                            export ANSIBLE_HOST_KEY_CHECKING=False

                            echo "[ssh_connection]" > ansible.cfg
                            echo "ssh_args = -o ProxyCommand=\\"ssh -W %h:%p -i $SSH_KEY ubuntu@${BASTION_IP}\\"" >> ansible.cfg

                            ansible-playbook -i inventory.ini site.yml --private-key=$SSH_KEY -u ubuntu
                        '''
                    }
                }
            }
        }

        stage('Show Access Info') {
            when { expression { env.ACTION == 'apply' } }
            steps {
                echo "==============================================="
                echo "TUNNEL COMMAND (run on your laptop)"
                echo ""
                echo "ssh -i ~/new-uday-key.pem -L 9090:${env.PRIVATE_IP}:9090 -L 9093:${env.PRIVATE_IP}:9093 -L 3000:${env.PRIVATE_IP}:3000 ubuntu@${env.BASTION_IP}"
                echo "==============================================="
            }
        }

    }

    post {
        success { echo "Pipeline Completed Successfully!" }
        failure { echo "Pipeline Failed! Check logs." }
    }
}
