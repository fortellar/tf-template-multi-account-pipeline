#!/bin/sh
# multi-account-terraform.sh
# Run Terraform for each AWS child account from the org root account
# Requires: AWS CLI, jq, Terraform, and valid AWS credentials with org:ListAccounts

set -e

# Initialize failure tracking using a file instead of array
FAILED_ACCOUNTS_FILE="/tmp/failed_accounts.txt"
rm -f "$FAILED_ACCOUNTS_FILE"
touch "$FAILED_ACCOUNTS_FILE"

# Get the account map from Terraform output, requires TFI
terraform output -json account_map | jq -r 'to_entries[] | "\(.key) \(.value)"' > /tmp/account_map.txt

# Delete our existing terraform if it exists to prevent any confusion/issues
rm -rf .terraform

# Backup original AWS credentials - we need them at the end of each account iteration
ORIG_AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID"
ORIG_AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY"
ORIG_AWS_SESSION_TOKEN="$AWS_SESSION_TOKEN"

while read -r ACCOUNT_ID ACCOUNT_NAME; do
  ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/OrganizationAccountAccessRole"

  # Get the AWS Account environment name, we will use this to generate the AWS S3 backend bucket name
  ENVIRONMENT=$(aws organizations list-tags-for-resource --resource-id "$ACCOUNT_ID" \
    | grep -A1 '"Key": "Environment"' \
    | grep '"Value":' \
    | sed -E 's/.*"Value": "(.*)".*/\1/')

  echo "\n=== Running Terraform for $ACCOUNT_NAME ($ACCOUNT_ID) ==="

  # Convert to lower case
  ENVIRONMENT=$(echo "$ENVIRONMENT" | tr '[:upper:]' '[:lower:]')
  ACCOUNT_NAME=$(echo "$ACCOUNT_NAME" | tr '[:upper:]' '[:lower:]')

  # Assume role and export credentials
  CREDS=$(aws sts assume-role --role-arn "$ROLE_ARN" --role-session-name "tf-multi-account-session" --output json)
  export AWS_ACCESS_KEY_ID=$(echo $CREDS | jq -r .Credentials.AccessKeyId)
  export AWS_SECRET_ACCESS_KEY=$(echo $CREDS | jq -r .Credentials.SecretAccessKey)
  export AWS_SESSION_TOKEN=$(echo $CREDS | jq -r .Credentials.SessionToken)

  # Re delete our existing terraform if it exists to prevent any confusion/issues
  rm -rf .terraform

  # Create a backend config file for this account (simple key-value format)
  BACKEND_FILE="backend-$ACCOUNT_ID.tfbackend"
  cat > $BACKEND_FILE <<EOF
bucket = "REPLACEME-$ENVIRONMENT-$ACCOUNT_NAME-terraform-state"
key    = "tf-map.tfstate"
region = "us-west-2"
encrypt = true
EOF

  # Run Terraform init, plan, and apply for this account with backend config
  if ! terraform init -input=false -backend-config=$BACKEND_FILE; then
    echo "Failed to initialize Terraform for account $ACCOUNT_NAME ($ACCOUNT_ID)"
    echo "$ACCOUNT_NAME ($ACCOUNT_ID)" >> "$FAILED_ACCOUNTS_FILE"
    continue
  fi

  if ! terraform plan -input=false -out=tfplan-$ACCOUNT_ID \
    -var="target_account_id=$ACCOUNT_ID" \
    -var="target_account_name=$ACCOUNT_NAME" \
    -var="child_account_automation=true"; then
    echo "Failed to plan Terraform for account $ACCOUNT_NAME ($ACCOUNT_ID)"
    echo "$ACCOUNT_NAME ($ACCOUNT_ID)" >> "$FAILED_ACCOUNTS_FILE"
    continue
  fi

  if ! terraform apply -input=false tfplan-$ACCOUNT_ID; then
    echo "Failed to apply Terraform for account $ACCOUNT_NAME ($ACCOUNT_ID)"
    echo "$ACCOUNT_NAME ($ACCOUNT_ID)" >> "$FAILED_ACCOUNTS_FILE"
    continue
  fi

  # Restore original AWS credentials for the next iteration
  export AWS_ACCESS_KEY_ID="$ORIG_AWS_ACCESS_KEY_ID"
  export AWS_SECRET_ACCESS_KEY="$ORIG_AWS_SECRET_ACCESS_KEY"
  export AWS_SESSION_TOKEN="$ORIG_AWS_SESSION_TOKEN"

done < /tmp/account_map.txt

echo "\nAll accounts processed."

# Cleanup temporary files
rm backend-*.tfbackend
rm tfplan-*

# More for local console debugging
rm -rf .terraform

# Check if any accounts failed and exit with appropriate status
if [ -s "$FAILED_ACCOUNTS_FILE" ]; then
  echo "\nThe following accounts failed:"
  cat "$FAILED_ACCOUNTS_FILE"
  rm -f "$FAILED_ACCOUNTS_FILE"
  exit 1
else
  echo "\nAll accounts processed successfully."
  rm -f "$FAILED_ACCOUNTS_FILE"
  exit 0
fi
