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
