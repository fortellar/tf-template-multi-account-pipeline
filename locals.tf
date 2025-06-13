locals {
  source_repo = lower(basename(path.cwd))

  # List of non-master (AWS Terminology) accounts in the organization
  non_master_accounts = try(data.aws_organizations_organization.org[0].non_master_accounts, "")

  # Map of non-master accounts with their IDs as keys and names as values
  account_map = try({ for acct in local.non_master_accounts : acct.id => acct.name }, "")
}

