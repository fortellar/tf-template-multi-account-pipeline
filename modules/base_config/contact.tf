resource "aws_account_alternate_contact" "operations" {
  alternate_contact_type = "OPERATIONS"

  name          = var.alternate_contacts.operations.name
  title         = var.alternate_contacts.operations.title
  email_address = var.alternate_contacts.operations.email_address
  phone_number  = var.alternate_contacts.operations.phone_number
}

resource "aws_account_alternate_contact" "billing" {
  alternate_contact_type = "BILLING"

  name          = var.alternate_contacts.billing.name
  title         = var.alternate_contacts.billing.title
  email_address = var.alternate_contacts.billing.email_address
  phone_number  = var.alternate_contacts.billing.phone_number
}

resource "aws_account_alternate_contact" "security" {
  alternate_contact_type = "SECURITY"

  name          = var.alternate_contacts.security.name
  title         = var.alternate_contacts.security.title
  email_address = var.alternate_contacts.security.email_address
  phone_number  = var.alternate_contacts.security.phone_number
}
