tflint {
  required_version = ">= 0.50"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "aws" {
    enabled = true
    version = "0.40.0"
    source  = "github.com/terraform-linters/tflint-ruleset-aws"
}
