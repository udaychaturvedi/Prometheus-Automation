pipeline {

    agent any

    parameters {
        choice(
            name: 'BUILD_TYPE',
            choices: ['plan', 'apply', 'destroy', 'ansible-deploy', 'verify'],
            description: 'Select the type of build to run'
        )
    }

    stages {

        stage('Clean Workspace') {
            steps { deleteDir() }
        }

        stage('Checkout') {
            steps { checkout scm }
        }

        stage('Terraform Init') {
            when { anyOf { 
                environment name: 'BUILD_TYPE', value: 'plan'
                environment name: 'BUILD_TYPE', value: 'apply'
                environment name: 'BUILD_TYPE', value: 'destroy'
            }}
            steps {
                dir('terraform') {
                    sh 'terraform init -reconfigure'
                }
            }
        }

        stage('Terraform Plan') {
            when { environment name: 'BUILD_TYPE', value: 'plan' }
            steps {
                dir('terraform') {
                    sh 'terraform plan'
                }
            }
        }

        stage('Approve Apply') {
            when { environment name: 'BUILD_TYPE', value: 'apply' }
            steps {
                input message: "Are you sure you want to APPLY?"
            }
        }

        stage('Terraform Apply') {
            when { environment name: 'BUILD_TYPE', value: 'apply' }
            steps {
                dir('terraform') {
                    sh 'terraform apply -auto-approve'
                }
            }
        }

        stage('Approve Destroy') {
            when { environment name: 'BUILD_TYPE', value: 'destroy' }
            steps {
                input message: "Destroy all infrastructure?"
            }
        }

        stage('Terraform Destroy') {
            when { environment name: 'BUILD_TYPE', value: 'destroy' }
            steps {
                dir('terraform') {
                    sh 'terraform destroy -auto-approve'
                }
            }
        }

        stage('Ansible Deploy') {
            when { environment name: 'BUILD_TYPE', value: 'ansible-deploy' }
            steps {

                withCredentials([
                    file(credentialsId: 'ec2-ssh-key-file', variable: 'SSH_KEY')
                ]) {

                    script {
                        // Fetch PRIVATE IP from Terraform
                        def prom_ip = sh(
                            script: "terraform -chdir=terraform output -raw prometheus_private_ip",
                            returnStdout: true
                        ).trim()

                        // Run Ansible roles
                        dir('ansible') {
                            sh """
                                ANSIBLE_HOST_KEY_CHECKING=False \
                                ansible-playbook -i inventory.yml site.yml \
                                --private-key \$SSH_KEY \
                                -e prometheus_ip=${prom_ip}
                            """
                        }
                    }
                }
            }
        }

        stage('Verify Prometheus') {
            when { environment name: 'BUILD_TYPE', value: 'verify' }
            steps {
                script {
                    sh 'curl -k https://prometheus.private.local:9090/-/ready || true'
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline Completed: ${currentBuild.currentResult}"
        }
    }
}

