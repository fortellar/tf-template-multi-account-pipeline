# Baseline configuration module for each AWS account
# Add resources like password policy, CloudTrail, etc. here

module "iam_account" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-account"
  version = "~> 5.58"

  account_alias = "REPLACEME-${lower(var.account_name)}"

  minimum_password_length   = 16
  password_reuse_prevention = 5

  # All other complexities are set to default values - https://github.com/terraform-aws-modules/terraform-aws-iam/blob/master/modules/iam-account/variables.tf
}
