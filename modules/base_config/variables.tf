variable "account_id" {
  description = "The AWS Account ID"
  type        = string # type string in case the Account Number starts with a 0
}

variable "account_name" {
  description = "The AWS Account Name"
  type        = string
}

variable "oidc_subjects" {
  description = "oidc Additional Subjects"
  type        = list(string)
  default     = []
}

variable "alternate_contacts" {
  description = "Alternate contacts for operations, billing, and security"
  type = object({
    operations = object({
      name          = string
      title         = string
      email_address = string
      phone_number  = string
    })
    billing = object({
      name          = string
      title         = string
      email_address = string
      phone_number  = string
    })
    security = object({
      name          = string
      title         = string
      email_address = string
      phone_number  = string
    })
  })
}

variable "enable_guardduty" {
  description = "Enable GuardDuty - Will provision IAM roles"
  type        = bool
}
