
# Start AWS Emulator if it is stopped
$container = docker ps -q --filter "name=^aws-emulator$"

if (-not $container) {
    docker start aws-emulator
}

# Configure AWS CLI and Terraform environment
$env:AWS_ENDPOINT_URL = "https://127.0.0.1:9297"
$env:AWS_SHARED_CREDENTIALS_FILE = "$env:USERPROFILE\.aws\emulator\9297\emulator_credentials"
$env:AWS_CONFIG_FILE = "$env:USERPROFILE\.aws\emulator\9297\config"
$env:AWS_CA_BUNDLE = "$env:USERPROFILE\.aws\emulator\9297\ca.pem"
$env:AWS_EC2_METADATA_DISABLED = "true"
$env:AWS_DISABLE_HOST_PREFIX_INJECTION = "true"
$env:AWS_REGION = "us-east-1"
$env:AWS_DEFAULT_REGION = "us-east-1"

Remove-Item Env:AWS_ACCESS_KEY_ID, Env:AWS_SECRET_ACCESS_KEY, Env:AWS_SESSION_TOKEN, Env:AWS_PROFILE -ErrorAction SilentlyContinue

# Verify emulator
aws sts get-caller-identity
  