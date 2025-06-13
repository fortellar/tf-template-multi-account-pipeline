terraform {
  required_version = ">= 1.10.0"

  backend "s3" {
    region       = "us-west-2"
    bucket       = "-terraform-state"
    key          = "tf-map.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
