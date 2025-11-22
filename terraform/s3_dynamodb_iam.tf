#################################################
# s3_dynamodb_iam.tf  (SAFE - no create for backend)
#
# NOTE: We DO NOT create the backend bucket/table or IAM policy here.
# Those must exist prior to terraform init/apply and are managed externally.
#################################################

# (Optional) reference existing S3 bucket - used only for informational/reference
# If you need to access the bucket in resources, use this data source.
data "aws_s3_bucket" "tfstate" {
  bucket = "uday-prometheus-terraform-state-ap-south-1"
}

# (Optional) reference existing DynamoDB table for locking (informational only)
data "aws_dynamodb_table" "tf_locks" {
  name = "uday-prometheus-terraform-locks"
}

# Keep the Jenkins role lookup (we DO NOT attach new policies from terraform)
data "aws_iam_role" "jenkins_role" {
  name = var.jenkins_role_name
}

# NOTE:
# - IAM policy creation and attachment removed because the instance role cannot create IAM policies.
# - S3 bucket and DynamoDB creation removed because the backend must be pre-created or managed separately.
# If you want the least-privilege IAM policy JSON to attach manually, I can provide it.

