pipeline {

    agent any

    environment {
        SSH_KEY_ID = 'ec2-ssh-key-file'   // Jenkins Credential (SSH private key)
    }

    stages {

        /* --- CLEAN WORKSPACE FIRST --- */
        stage('Clean Workspace') {
            steps {
                deleteDir()
            }
        }

        /* --- CHECKOUT YOUR GITHUB CODE --- */
        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/udaychaturvedi/Prometheus-Automation.git'
            }
        }

        /* --- TERRAFORM INIT --- */
        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    sh 'terraform init -reconfigure'
                }
            }
        }

        /* --- ASK USER: APPLY OR DESTROY --- */
        stage('Choose Action') {
            steps {
                script {
                    ACTION = input(
                        message: "Choose Terraform Action",
                        parameters: [
                            choice(
                                name: 'action',
                                choices: ['apply', 'destroy'],
                                description: 'Select apply or destroy'
                            )
                        ]
                    )
                    echo "User selected: ${ACTION}"
                }
            }
        }

        /* --- TERRAFORM APPLY --- */
        stage('Terraform Apply') {
            when { expression { ACTION == 'apply' } }
            steps {
                dir('terraform') {
                    sh 'terraform apply -auto-approve'
                }
            }
        }

        /* --- TERRAFORM DESTROY --- */
        stage('Terraform Destroy') {
            when { expression { ACTION == 'destroy' } }
            steps {
                dir('terraform') {
                    sh 'terraform destroy -auto-approve'
                }
            }
        }

        /* --- FETCH PUBLIC IP --- */
        stage('Get Public IP') {
            when { expression { ACTION == 'apply' } }
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

        /* --- RUN ANSIBLE FULL DEPLOYMENT --- */
        stage('Run Ansible Deployment') {
            when { expression { ACTION == 'apply' } }

            steps {
                withCredentials([
                    file(credentialsId: SSH_KEY_ID, variable: 'SSH_KEY')
                ]) {
                    dir('ansible') {
                        sh """
                            ANSIBLE_HOST_KEY_CHECKING=False \
                            ansible-playbook \
                            -i inventory_aws_ec2.yml \
                            site.yml \
                            --private-key \$SSH_KEY
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline Completed Successfully!"
        }
        failure {
            echo "Pipeline Failed — Check Logs!"
        }
    }
}
