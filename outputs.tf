output "account_map" {
  description = "AWS Organization account map"
  value       = try(local.account_map, "")
}

output "target_account_id" {
  description = "AWS Account ID to target in MAP"
  value       = var.target_account_id
}

output "target_account_name" {
  description = "AWS Account Name to target in MAP"
  value       = var.target_account_name
}

output "oidc_role" {
  description = "OIDC Role ARN for GitHub Actions"
  value       = try(module.base_config.oidc_role, "")
}
