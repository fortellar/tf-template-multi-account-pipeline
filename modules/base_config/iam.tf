# Baseline configuration module for each AWS account
# Add resources like password policy, CloudTrail, etc. here

module "iam_account" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-account"
  version = "~> 5.58"

  account_alias = "REPLACEME-${lower(var.account_name)}"

  minimum_password_length   = 16
  password_reuse_prevention = 5

  # All other complexities are set to default values - https://github.com/terraform-aws-modules/terraform-aws-iam/blob/master/modules/iam-account/variables.tf
}

# NIST 800-171 compliance, relies upon NIST NIST 800-63B
# https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-171r2.pdf
module "iam_account" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-account"
  version = "~> 5.58"

  account_alias = "fortellar-${lower(var.account_name)}"

  minimum_password_length   = var.nist_800_171 ? 16 : 12 #gitleaks:allow
  password_reuse_prevention = var.nist_800_171 ? 24 : 5  #gitleaks:allow
  max_password_age          = var.nist_800_171 ? 90 : 0  #gitleaks:allow

  require_uppercase_characters   = var.nist_800_171 ? false : true
  require_lowercase_characters   = var.nist_800_171 ? false : true
  require_numbers                = var.nist_800_171 ? false : true
  require_symbols                = var.nist_800_171 ? false : true
  allow_users_to_change_password = true

  # All other complexities are set to default values - https://github.com/terraform-aws-modules/terraform-aws-iam/blob/master/modules/iam-account/variables.tf
}

data "aws_iam_policy_document" "guardduty_s3" {
  statement {
    sid    = "AllowManagedRuleToSendS3EventsToGuardDuty"
    effect = "Allow"
    actions = [
      "events:PutRule"
    ]
    resources = [
      "arn:aws:events:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:rule/DO-NOT-DELETE-AmazonGuardDutyMalwareProtectionS3*"
    ]

    condition {
      test     = "StringEquals"
      variable = "events:ManagedBy"
      values   = ["malware-protection-plan.guardduty.amazonaws.com"]
    }

    condition {
      test     = "ForAllValues:StringEquals"
      variable = "events:source"
      values   = ["aws.s3"]
    }

    condition {
      test     = "ForAllValues:StringEquals"
      variable = "events:detail-type"
      values   = ["Object Created", "AWS API Call via CloudTrail"]
    }

    condition {
      test     = "Null"
      variable = "events:source"
      values   = ["false"]
    }

    condition {
      test     = "Null"
      variable = "events:detail-type"
      values   = ["false"]
    }
  }

  statement {
    sid    = "AllowUpdateTargetAndDeleteManagedRule"
    effect = "Allow"
    actions = [
      "events:DeleteRule",
      "events:PutTargets",
      "events:RemoveTargets"
    ]
    resources = [
      "arn:aws:events:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:rule/DO-NOT-DELETE-AmazonGuardDutyMalwareProtectionS3*"
    ]

    condition {
      test     = "StringEquals"
      variable = "events:ManagedBy"
      values   = ["malware-protection-plan.guardduty.amazonaws.com"]
    }
  }

  statement {
    sid    = "AllowGuardDutyToMonitorEventBridgeManagedRule"
    effect = "Allow"
    actions = [
      "events:DescribeRule",
      "events:ListTargetsByRule"
    ]
    resources = [
      "arn:aws:events:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:rule/DO-NOT-DELETE-AmazonGuardDutyMalwareProtectionS3*"
    ]
  }

  statement {
    sid    = "AllowEnableS3EventBridgeEvents"
    effect = "Allow"
    actions = [
      "s3:PutBucketNotification",
      "s3:GetBucketNotification"
    ]
    resources = [
      "arn:aws:s3:::security-prd-guardduty"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  statement {
    sid    = "AllowPostScanTag"
    effect = "Allow"
    actions = [
      "s3:GetObjectTagging",
      "s3:GetObjectVersionTagging",
      "s3:PutObjectTagging",
      "s3:PutObjectVersionTagging"
    ]
    resources = [
      "arn:aws:s3:::*/*",
      "arn:aws:s3:::*"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  statement {
    sid    = "AllowPutValidationObject"
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::*/malware-protection-resource-validation-object"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  statement {
    sid    = "AllowCheckBucketOwnership"
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::*"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  statement {
    sid    = "AllowMalwareScan"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion"
    ]
    resources = [
      "arn:aws:s3:::*/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_policy" "guardduty_s3" {
  count = var.enable_guardduty ? 1 : 0

  name        = "guardduty_s3"
  path        = "/"
  description = "GuardDuty S3 Policy"

  policy = data.aws_iam_policy_document.guardduty_s3.json
}

module "guardduty_s3" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 5.58"

  create_role = var.enable_guardduty

  trusted_role_services = [
    "malware-protection-plan.guardduty.amazonaws.com"
  ]

  trust_policy_conditions = [
    {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    },
    {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:guardduty:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:malware-protection-plan/*"]
    }
  ]

  role_name         = "GuardDutyS3MalwareScanRole"
  role_requires_mfa = false
  role_path         = "/"

  custom_role_policy_arns = [
    aws_iam_policy.guardduty_s3[0].arn
  ]
  number_of_custom_role_policy_arns = 1

}
