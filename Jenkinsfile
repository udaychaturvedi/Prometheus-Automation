pipeline {
  agent any
  environment {
    TF_WORKING_DIR = 'terraform'
  }
  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }
    stage('Terraform Init') {
      steps {
        dir("${env.TF_WORKING_DIR}") {
          sh 'terraform init -reconfigure'
        }
      }
    }
    stage('Terraform Plan') {
      steps {
        dir("${env.TF_WORKING_DIR}") {
          sh 'terraform plan -out plan.tfplan'
          sh 'terraform show -json plan.tfplan > plan.json || true'
        }
      }
    }
    stage('Manual Approval') {
      steps {
        input message: "Approve terraform apply?", ok: "Apply"
      }
    }
    stage('Terraform Apply') {
      steps {
        dir("${env.TF_WORKING_DIR}") {
          sh 'terraform apply -auto-approve "plan.tfplan"'
        }
      }
    }
    stage('Fetch Outputs and Run Ansible') {
      steps {
        dir("${env.TF_WORKING_DIR}") {
          sh 'terraform output -json > ../tf_outputs.json'
        }
        sh '''
          python3 - <<'PY'
import json,sys
o=json.load(open('tf_outputs.json'))
bip=o['bastion_public_ip']['value']
pubdns=o['bastion_public_dns']['value']
print("Bastion:",bip,pubdns)
# create ansible inventory
with open('ansible/inventory/hosts','w') as f:
    f.write("[bastion]\\n{} ansible_user=ubuntu\\n\\n".format(bip))
# For Prometheus ASG, we will use private IPs fetched by AWS CLI in real runs (Jenkins role has permissions)
# Jenkins will ssh to bastion and run ansible-playbooks via ProxyCommand
PY
'''
        // Run Ansible via bastion (assumes key is present on Jenkins or uses instance role)
        sh '''
          # Example: run nginx on bastion then run prometheus playbook via bastion
          ssh -o StrictHostKeyChecking=no ubuntu@$(jq -r .bastion_public_ip.value tf_outputs.json) 'sudo systemctl status nginx || sudo systemctl start nginx'
          # copy ansible code to bastion and run from there or use ansible->ssh proxy
          # For brevity we run playbooks locally with --private-key pointing to pem (if available)
          ansible-playbook -i ansible/inventory/hosts ansible/playbooks/nginx.yml --ssh-common-args='-o ProxyCommand="ssh -W %h:%p -q ubuntu@'$(jq -r .bastion_public_ip.value tf_outputs.json)'"'
          ansible-playbook -i ansible/inventory/hosts ansible/playbooks/prometheus.yml --ssh-common-args='-o ProxyCommand="ssh -W %h:%p -q ubuntu@'$(jq -r .bastion_public_ip.value tf_outputs.json)'"'
        '''
      }
    }
  }
  post {
    always {
      echo "Pipeline finished. Check Jenkins console for outputs."
    }
  }
}

