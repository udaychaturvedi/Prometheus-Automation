pipeline {
    agent any

    environment {
        TF_DIR = "terraform"
        BASTION_IP = "13.201.63.0"
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

        stage('Select Action') {
            steps {
                script {
                    env.ACTION = input(
                        message: "Choose action",
                        parameters: [
                            choice(name: 'ACTION', choices: ['apply', 'destroy'], description: '')
                        ]
                    )
                }
            }
        }

        stage('Terraform Apply/Destroy') {
            steps {
                dir(env.TF_DIR) {
                    script {
                        if (env.ACTION == 'apply') {
                            sh 'terraform apply -auto-approve -lock=false'
                        } else {
                            sh 'terraform destroy -auto-approve -lock=false'
                        }
                    }
                }
            }
        }

        stage('Fetch Private IP') {
            when { expression { env.ACTION == 'apply' } }
            steps {
                dir(env.TF_DIR) {
                    script {
                        env.PROM_PRIVATE_IP = sh(script: "terraform output -raw prometheus_private_ip", returnStdout: true).trim()
                        echo "Prometheus Private IP: ${env.PROM_PRIVATE_IP}"
                    }
                }
            }
        }

        stage('Run Ansible (via bastion)') {
            when { expression { env.ACTION == 'apply' } }
            steps {
                withCredentials([file(credentialsId: 'new-uday-key', variable: 'SSH_KEY')]) {
                    dir('ansible') {
                        sh '''
                        set -e
                        echo "Creating dynamic inventory..."

                        cat > inventory.ini <<EOF
[prometheus]
${PROM_PRIVATE_IP} ansible_user=ubuntu ansible_ssh_private_key_file=${SSH_KEY}

[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o ProxyCommand="ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no -W %h:%p ubuntu@${BASTION_IP}"'
EOF

                        ansible-playbook -i inventory.ini site.yml
                        '''
                    }
                }
            }
        }

        stage('Show Access Links') {
            when { expression { env.ACTION == 'apply' } }
            steps {
                echo "============================================"
                echo "Prometheus   → http://localhost:9090"
                echo "Grafana      → http://localhost:3000"
                echo "Alertmanager → http://localhost:9093"
                echo ""
                echo "Run SSH tunnel:"
                echo """
ssh -i ~/new-uday-key.pem \\
  -L 9090:${PROM_PRIVATE_IP}:9090 \\
  -L 3000:${PROM_PRIVATE_IP}:3000 \\
  -L 9093:${PROM_PRIVATE_IP}:9093 \\
  ubuntu@${BASTION_IP}
                """
                echo "============================================"
            }
        }
    }

    post {
        success { echo "Pipeline completed successfully!" }
        failure { echo "Pipeline failed — check logs." }
    }
}
