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

        stage('Clean Terraform Lock (best-effort)') {
            steps {
                echo "Attempting to remove stale DynamoDB lock (no-op if not present)..."
                sh '''
                  aws dynamodb delete-item --table-name terraform-locks --key '{"LockID":{"S":"prometheus/terraform.tfstate"}}' || true
                '''
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
                        message: "Select action",
                        parameters: [choice(name: 'ACTION', choices: ['apply','destroy'], description: '')]
                    )
                    echo "Selected: ${env.ACTION}"
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

        stage('Get Outputs') {
            when { expression { env.ACTION == 'apply' } }
            steps {
                dir(env.TF_DIR) {
                    script {
                        env.BASTION_IP = sh(script: "terraform output -raw bastion_public_ip", returnStdout: true).trim()
                        env.PROM_PRIVATE_IP = sh(script: "terraform output -raw prometheus_private_ip", returnStdout: true).trim()
                        env.PROM_PUBLIC_IP = sh(script: "terraform output -raw prometheus_public_ip", returnStdout: true).trim()
                        echo "Bastion IP: ${env.BASTION_IP}"
                        echo "Prometheus Private IP: ${env.PROM_PRIVATE_IP}"
                        echo "Prometheus Public IP (if any): ${env.PROM_PUBLIC_IP}"
                    }
                }
            }
        }

        stage('Run Ansible via Bastion') {
            when { expression { env.ACTION == 'apply' } }
            steps {
                withCredentials([file(credentialsId: 'new-uday-key', variable: 'SSH_KEY')]) {
                    dir('ansible') {
                        sh """
                        set -e
                        chmod 600 $SSH_KEY

                        # build inventory with private IP
                        cat > inventory.ini <<EOF
[prometheus]
${PROM_PRIVATE_IP} ansible_user=ubuntu ansible_ssh_private_key_file=${SSH_KEY}
EOF

                        # create ansible.cfg to use ProxyCommand via bastion
                        cat > ansible.cfg <<EOF
[defaults]
inventory = inventory.ini
host_key_checking = False

[ssh_connection]
ssh_args = -o ProxyCommand="ssh -W %h:%p -i ${SSH_KEY} ubuntu@${BASTION_IP}"
EOF

                        echo "Running Ansible playbook (via bastion proxy)..."
                        ansible-playbook -i inventory.ini site.yml --private-key=$SSH_KEY -u ubuntu
                        """
                    }
                }
            }
        }

        stage('Show Access Info') {
            when { expression { env.ACTION == 'apply' } }
            steps {
                echo "=============================================="
                echo "Prometheus private : http://${PROM_PRIVATE_IP}:9090"
                echo "Grafana private    : http://${PROM_PRIVATE_IP}:3000"
                echo "Alertmanager       : http://${PROM_PRIVATE_IP}:9093"
                echo ""
                echo "Run this locally to tunnel (on your laptop):"
                echo "ssh -i ~/new-uday-key.pem -L 9090:${PROM_PRIVATE_IP}:9090 -L 9093:${PROM_PRIVATE_IP}:9093 -L 3000:${PROM_PRIVATE_IP}:3000 ubuntu@${BASTION_IP}"
                echo "Then open http://localhost:9090 and http://localhost:3000"
                echo "=============================================="
            }
        }
    }

    post {
        success {
            echo "Pipeline completed successfully"
        }
        failure {
            echo "Pipeline failed - check logs"
        }
    }
}
