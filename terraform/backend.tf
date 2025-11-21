terraform {
  backend "s3" {
    bucket         = "prometheus-terraform-state-uday123-new"
    key            = "prometheus/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
