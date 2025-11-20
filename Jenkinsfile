pipeline {

    agent any

    parameters {
        choice(
            name: 'BUILD_TYPE',
            choices: ['plan', 'apply', 'destroy', 'ansible-deploy'],
            description: 'Choose what you want Jenkins to do'
        )
    }

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
            when {
                anyOf {
                    environment name: 'BUILD_TYPE', value: 'plan'
                    environment name: 'BUILD_TYPE', value: 'apply'
                    environment name: 'BUILD_TYPE', value: 'destroy'
                }
            }
            steps {
                dir('terraform') {
                    sh 'terraform init -reconfigure'
                }
            }
        }

        /* -------------------- TERRAFORM PLAN -------------------- */
        stage('Terraform Plan') {
            when {
                environment name: 'BUILD_TYPE', value: 'plan'
            }
            steps {
                dir('terraform') {
                    sh 'terraform plan'
                }
            }
        }

        /* -------------------- TERRAFORM APPLY -------------------- */
        stage('User Approval (Apply)') {
            when {
                environment name: 'BUILD_TYPE', value: 'apply'
            }
            steps {
                input message: "Are you sure you want to APPLY infrastructure?"
            }
        }

        stage('Terraform Apply') {
            when {
                environment name: 'BUILD_TYPE', value: 'apply'
            }
            steps {
                dir('terraform') {
                    sh 'terraform apply -auto-approve'
                }
            }
        }

        /* -------------------- TERRAFORM DESTROY -------------------- */
        stage('User Approval (Destroy)') {
            when {
                environment name: 'BUILD_TYPE', value: 'destroy'
            }
            steps {
                input message: "Are you sure you want to DESTROY infrastructure?"
            }
        }

        stage('Terraform Destroy') {
            when {
                environment name: 'BUILD_TYPE', value: 'destroy'
            }
            steps {
                dir('terraform') {
                    sh 'terraform destroy -auto-approve'
                }
            }
        }

        /* -------------------- ANSIBLE DEPLOY -------------------- */
        stage('Run Ansible Deployment') {
            when {
                environment name: 'BUILD_TYPE', value: 'ansible-deploy'
            }

            steps {

                withCredentials([
                    file(credentialsId: 'ec2-ssh-key-file', variable: 'SSH_KEY')
                ]) {

                    script {
                        echo "Fetching instance private IP..."
                        def private_ip = sh(
                            script: "terraform -chdir=terraform output -raw prometheus_private_ip",
                            returnStdout: true
                        ).trim()

                        echo "Running Ansible on: ${private_ip}"

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
    }

    post {
        success {
            echo "Pipeline executed successfully!"
        }
        failure {
            echo "Pipeline failed! Please check logs."
        }
    }
}
