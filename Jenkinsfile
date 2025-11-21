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
                        echo "Prometheus Private IP retrieved: ${env.PROM_PRIVATE_IP}"
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
ansible_ssh_common_args='-o ProxyCommand="ssh -i ${SSH_KEY} -W %h:%p ubuntu@13.201.63.0"'
EOF

                        echo "Running Ansible..."
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
                echo "Prometheus   (via SSH Tunnel): http://localhost:9090"
                echo "Grafana      (via SSH Tunnel): http://localhost:3000"
                echo "Alertmanager (via SSH Tunnel): http://localhost:9093"
                echo ""
                echo "To create the tunnel, run:"
                echo ""
                echo "ssh -i ~/new-uday-key.pem \\"
                echo "  -L 9090:${PROM_PRIVATE_IP}:9090 \\"
                echo "  -L 3000:${PROM_PRIVATE_IP}:3000 \\"
                echo "  -L 9093:${PROM_PRIVATE_IP}:9093 \\"
                echo "  ubuntu@13.201.63.0"
                echo ""
                echo "============================================"
            }
        }
    }

    post {
        success { echo "Pipeline completed successfully!" }
        failure { echo "Pipeline failed — check logs." }
    }
}
