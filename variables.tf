variable "region" {
  description = "AWS region to use"
  type        = string
  default     = "us-west-2"
}

variable "target_account_id" {
  description = "The AWS Account ID to target."
  type        = string
  default     = ""
}

variable "target_account_name" {
  description = "The AWS Account Name to target."
  type        = string
  default     = ""
}

variable "child_account_automation" {
  description = "Enable child account automation"
  type        = bool
  default     = false
}

# Use a per account map lookup when referencing these
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
