terraform {
  backend "s3" {
    bucket         = "uday-prometheus-terraform-state-ap-south-1"
    key            = "prometheus/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "uday-prometheus-terraform-locks"
    encrypt        = true
  }
}

