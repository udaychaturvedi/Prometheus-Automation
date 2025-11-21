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
                    def ACTION = input(
                        message: "What do you want to do?",
                        parameters: [choice(
                            name: 'ACTION',
                            choices: ['apply', 'destroy'],
                            description: 'Select action'
                        )]
                    )
                    env.ACTION = ACTION
                    echo "Selected action: ${env.ACTION}"
                }
            }
        }

        stage('Terraform Apply') {
            when { expression { env.ACTION == 'apply' } }
            steps {
                dir('terraform') {
                    sh 'terraform apply -auto-approve'
                }
            }
        }

        stage('Terraform Destroy') {
            when { expression { env.ACTION == 'destroy' } }
            steps {
                dir('terraform') {
                    sh 'terraform destroy -auto-approve'
                }
            }
        }

        stage('Wait for EC2') {
            when { expression { env.ACTION == 'apply' } }
            steps {
                echo "⏳ Waiting 45 seconds for EC2 startup..."
                sh "sleep 45"
            }
        }

        stage('Get Public IP') {
            when { expression { env.ACTION == 'apply' } }
            steps {
                script {
                    def PUBLIC_IP = sh(
                        script: 'terraform -chdir=terraform output -raw prometheus_public_ip',
                        returnStdout: true
                    ).trim()

                    env.PROM_PUBLIC_IP = PUBLIC_IP
                    echo "Prometheus Public IP = ${env.PROM_PUBLIC_IP}"
                }
            }
        }

        stage('Run Ansible Deployment') {
            when { expression { env.ACTION == 'apply' } }
            steps {
                withCredentials([file(credentialsId: 'new-uday-key', variable: 'SSH_KEY')]) {

                    dir('ansible') {
                        sh '''
                        set -e
                        chmod 600 "$SSH_KEY"

                        export SSH_KEY="$SSH_KEY"
                        export ANSIBLE_HOST_KEY_CHECKING=False

                        ansible-playbook \
                            -i inventory_aws_ec2.yml \
                            site.yml \
                            --private-key "$SSH_KEY"
                        '''
                    }
                }
            }
        }

        stage('Show Access URLs') {
            when { expression { env.ACTION == 'apply' } }
            steps {
                echo "=============================================="
                echo "Prometheus   : http://${env.PROM_PUBLIC_IP}:9090"
                echo "Alertmanager : http://${env.PROM_PUBLIC_IP}:9093"
                echo "Grafana      : http://${env.PROM_PUBLIC_IP}:3000"
                echo "=============================================="
            }
        }
    }

    post {
        success {
            echo " Pipeline Completed Successfully!"
        }
        failure {
            echo " Pipeline Failed! Check logs."
        }
    }
}
