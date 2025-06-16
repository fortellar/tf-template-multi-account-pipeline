module "base_config" {
  source = "./modules/base_config"
  count  = var.child_account_automation ? 1 : 0

  account_id    = var.target_account_id
  account_name  = var.target_account_name
  oidc_subjects = var.oidc_subjects
}
