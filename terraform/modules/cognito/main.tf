# terraform/modules/cognito/main.tf

# Cognito User Pool: Stores user accounts
variable "project_name" {
  description = "The name of the project to prefix resource names."
  type        = string
}
resource "aws_cognito_user_pool" "user_pool" {
  name = "${var.project_name}-user-pool"

  # Policies for user pool
  password_policy {
    minimum_length    = 12 # Minimum password length
    # Password complexity requirements
    # Set to true to require lowercase, numbers, uppercase, and symbols
    require_lowercase = true
    require_numbers   = true
    require_uppercase = true
    require_symbols   = false # Can be set to true if symbols are required
  }

  # Attributes to be verified (e.g., email or phone)
  auto_verified_attributes = ["email"]

  # Schema for user attributes
  schema {
    name                     = "email"
    attribute_data_type      = "String"
    mutable                  = true
    required                 = true
    developer_only_attribute = false
  }

}

# Cognito User Pool Client: Allows applications to interact with the User Pool
resource "aws_cognito_user_pool_client" "user_pool_client" {
  name                          = "${var.project_name}-app-client"
  user_pool_id                  = aws_cognito_user_pool.user_pool.id
  generate_secret               = false # Set to true for server-side apps, false for client-side (like a web app)
  explicit_auth_flows           = ["ADMIN_NO_SRP_AUTH", "USER_PASSWORD_AUTH", "REFRESH_TOKEN_AUTH"] # Common flows

  # Callback URLs are required if using hosted UI or OAuth flows
  # Add your frontend application's URL here for successful authentication redirects
  # callback_urls = ["http://localhost:3000", "https://your-frontend-domain.com"]
  # logout_urls = ["http://localhost:3000", "https://your-frontend-domain.com"]

# tags = {
   # Environment = "production"
   # Project     = var.project_name
#  }#

  # Optional: Enable token revocation
 # prevent_user_existence_errors = "ENABLED" # Helps to prevent user enumeration attacks

  # Optional: Set the refresh token validity period
 # refresh_token_validity = 30 # Days

  # Optional: Set the access token validity period
 # access_token_validity = 60 # Minutes

  # Optional: Set the ID token validity period
 # id_token_validity = 60 # Minutes

 # tags = {
 #   Environment = "production"
 #   Project     = var.project_name
 # }
  # Optional: Enable MFA (Multi-Factor Authentication)
  # mfa_configuration = "OPTIONAL" # Set to "REQUIRED" if you want to enforce MFA
}

# Cognito Identity Pool: Allows users to get temporary AWS credentials for accessing other AWS services
resource "aws_cognito_identity_pool" "identity_pool" {
  identity_pool_name = "${var.project_name}-identity-pool"
  allow_unauthenticated_identities = false # Set to true if you need guest access

  # Attach the user pool to the identity pool
  cognito_identity_providers {
    client_id              = aws_cognito_user_pool_client.user_pool_client.id
    provider_name          = aws_cognito_user_pool.user_pool.endpoint # Format: cognito-idp.<region>.amazonaws.com/<user_pool_id>
    server_side_token_check = false # Set to true to enforce token validation (recommended for production)
  }

  tags = {
    Environment = "production"
    Project     = var.project_name
  }
}

# Output values
output "user_pool_id" {
  description = "The ID of the Cognito User Pool."
  value       = aws_cognito_user_pool.user_pool.id
}

output "user_pool_arn" {
  description = "The ARN of the Cognito User Pool."
  value       = aws_cognito_user_pool.user_pool.arn
}

output "user_pool_client_id" {
  description = "The ID of the Cognito User Pool Client."
  value       = aws_cognito_user_pool_client.user_pool_client.id
}

output "identity_pool_id" {
  description = "The ID of the Cognito Identity Pool."
  value       = aws_cognito_identity_pool.identity_pool.id
}

