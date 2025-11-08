terraform {
  backend "s3" {
    bucket         = "my-terraform-state-<your-name>"   # <- replace after creating S3
    key            = "prometheus/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-locks"                 # <- replace after creating DynamoDB
    encrypt        = true
  }
}
