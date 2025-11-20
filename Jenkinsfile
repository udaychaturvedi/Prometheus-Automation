pipeline {
    agent any

    stages {

        stage('Clean Workspace') {
            steps { deleteDir() }
        }

        stage('Checkout Code') {
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
                dir('terraform') {
                    sh 'terraform init -reconfigure'
                }
            }
        }

        stage('Choose Action') {
            steps {
                script {
                    ACTION = input(
                        message: "What do you want to do?",
                        parameters: [choice(
                            name: 'ACTION',
                            choices: ['apply', 'destroy'],
                            description: 'Select action'
                        )]
                    )
                    echo "User selected: ${ACTION}"
                }
            }
        }

        stage('Terraform Apply') {
            when { expression { ACTION == 'apply' } }
            steps {
                dir('terraform') {
                    sh 'terraform apply -auto-approve'
                }
            }
        }

        stage('Terraform Destroy') {
            when { expression { ACTION == 'destroy' } }
            steps {
                dir('terraform') {
                    sh 'terraform destroy -auto-approve'
                }
            }
        }

        stage('Wait for EC2 to be Ready') {
            when { expression { ACTION == 'apply' } }
            steps {
                script {
                    echo "⏳ Waiting 45 seconds for EC2 boot & SSH readiness..."
                    sh "sleep 45"
                }
            }
        }

        stage('Get Public IP') {
            when { expression { ACTION == 'apply' } }
            steps {
                script {
                    PUBLIC_IP = sh(
                        script: 'terraform -chdir=terraform output -raw prometheus_public_ip',
                        returnStdout: true
                    ).trim()

                    echo "Prometheus Public IP = ${PUBLIC_IP}"
                }
            }
        }

        stage('Run Ansible Deployment') {
            when { expression { ACTION == 'apply' } }
            steps {
                withCredentials([sshUserPrivateKey(
                    credentialsId: 'ec2-ssh-key-file',   // ✅ FIXED!
                    keyFileVariable: 'SSH_KEY'
                )]) {
                    dir('ansible') {
                        sh '''
                        export SSH_KEY=$SSH_KEY
                        ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
                        -i inventory_aws_ec2.yml site.yml \
                        --private-key $SSH_KEY
                        '''
                    }
                }
            }
        }

        stage('Show URLs') {
            when { expression { ACTION == 'apply' } }
            steps {
                script {
                    echo "=============================================="
                    echo "Prometheus   : http://${PUBLIC_IP}:9090"
                    echo "Alertmanager : http://${PUBLIC_IP}:9093"
                    echo "Grafana      : http://${PUBLIC_IP}:3000"
                    echo "=============================================="
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline Completed Successfully!"
        }
        failure {
            echo "Pipeline failed! Check logs."
        }
    }
}
