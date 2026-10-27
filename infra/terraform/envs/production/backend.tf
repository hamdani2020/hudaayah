terraform {
  backend "s3" {
    bucket       = "hudaayah-tfstate"
    key          = "backend/production/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
