# Create the identity provider
module "iam_github_oidc_provider" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-provider"
  version = "~> 5.58"
}

# Create the IAM role
module "iam_github_oidc_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "~> 5.58"

  # This should be updated to suit your organization, repository, references/branches, etc.
  name = "github-oidc"
  subjects = distinct(concat(
    ["REPLACEME/tf-${var.account_name}-*"], # This will include tf-<account_name>-* by default for all GitHub repos for all branches. We will control deployments on the repos themselves.
    var.oidc_subjects
  ))

  policies = {
    S3ReadOnly = "arn:aws:iam::aws:policy/AdministratorAccess"
  }
}
