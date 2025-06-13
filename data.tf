data "aws_organizations_organization" "org" {
  count = var.child_account_automation == false ? 1 : 0
}
