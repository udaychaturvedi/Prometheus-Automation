resource "aws_s3_bucket" "tfstate" {
  bucket = "uday-prometheus-terraform-state-ap-south-1"
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  versioning {
    enabled = true
  }

  tags = {
    Name = "uday-prometheus-tfstate"
  }
}

resource "aws_dynamodb_table" "tf_locks" {
  name         = "uday-prometheus-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "uday-prometheus-locks"
  }
}

data "aws_iam_role" "jenkins_role" {
  name = var.jenkins_role_name
}

resource "aws_iam_policy" "jenkins_tf_policy" {
  name        = "jenkins-terraform-policy-uday"
  description = "Least-privilege policy for Jenkins to run Terraform for Prometheus infra"

  policy = file("${path.module}/iam/jenkins_policy.json")
}

resource "aws_iam_role_policy_attachment" "attach_jenkins_policy" {
  role       = data.aws_iam_role.jenkins_role.name
  policy_arn = aws_iam_policy.jenkins_tf_policy.arn
}

