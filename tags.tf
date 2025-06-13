locals {
  common_tags = {
    SourceRepo  = local.source_repo
    Provisioner = "Terraform"
    Terraform   = "true"
  }
}
