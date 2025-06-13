output "account_id" {
  description = "AWS Account ID"
  value       = var.account_id
}

output "account_name" {
  description = "AWS Account Name"
  value       = var.account_name
}

output "oidc_role" {
  description = "OIDC Role ARN for GitHub Actions"
  value       = module.iam_github_oidc_role.arn
}
