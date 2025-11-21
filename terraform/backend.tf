terraform {
  backend "s3" {
    bucket = "prometheus-terraform-state-uday123"
    key    = "prometheus/terraform.tfstate"
    region = "ap-south-1"
    dynamodb_table = "terraform-locks"
    encrypt = true
  }
}

