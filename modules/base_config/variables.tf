variable "account_id" {
  description = "The AWS Account ID"
  type        = string # type string in case the Account Number starts with a 0
}

variable "account_name" {
  description = "The AWS Account Name"
  type        = string
}

variable "odic_subjects" {
  description = "ODIC Additional Subjects"
  type        = list(string)
  default     = []
}
