# modules/iam/main.tf

resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_dynamodb_policy" {
  name = "${var.project_name}-dynamodb-access-policy"
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "dynamodb:BatchGetItem",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan",
          "dynamodb:Query",
        ],
        Effect   = "Allow",
        Resource = var.table_arn # Grants access to the specific DynamoDB table
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        # Use the passed aws_account_id variable for the log group ARN
        Resource = "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/lambda/${var.project_name}-*:*"
      }
    ]
  })
}

# IAM role for authenticated users in Cognito Identity Pool
resource "aws_iam_role" "cognito_auth_role" {
  name = "${var.project_name}-CognitoAuthRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = var.identity_pool_id
          },
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "authenticated"
          }
        }
      }
    ]
  })
}

# Policy for authenticated Cognito users (e.g., allowing access to specific S3 buckets, etc.)
# For this To-Do app, they don't directly access DynamoDB. Lambda acts as a proxy.
resource "aws_iam_role_policy" "cognito_auth_policy" {
  name = "${var.project_name}-CognitoAuthPolicy"
  role = aws_iam_role.cognito_auth_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "mobileanalytics:PutEvents",
          "cognito-sync:*"
        ],
        Resource = "*"
      },
      # Add more specific permissions here if authenticated users need direct AWS access (e.g., S3 read)
    ]
  })
}

# IAM role for unauthenticated users in Cognito Identity Pool (if allow_unauthenticated_identities is true)
# Not strictly needed if allow_unauthenticated_identities is false in identity_pool
resource "aws_iam_role" "cognito_unauth_role" {
  name = "${var.project_name}-CognitoUnauthRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = var.identity_pool_id
          },
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "unauthenticated"
          }
        }
      }
    ]
  })
}

# Policy for unauthenticated Cognito users
resource "aws_iam_role_policy" "cognito_unauth_policy" {
  name = "${var.project_name}-CognitoUnauthPolicy"
  role = aws_iam_role.cognito_unauth_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "mobileanalytics:PutEvents",
          "cognito-sync:*"
        ],
        Resource = "*"
      },
    ]
  })
}

# Attach roles to the Identity Pool
resource "aws_cognito_identity_pool_roles_attachment" "roles_attachment" {
  identity_pool_id = var.identity_pool_id
  roles = {
    "authenticated"   = aws_iam_role.cognito_auth_role.arn
    "unauthenticated" = aws_iam_role.cognito_unauth_role.arn
  }
}

# Input variables for this module
variable "aws_account_id" {
  description = "The AWS account ID for permissions within this module."
  type        = string
}

variable "aws_region" {
  description = "The AWS region where resources are deployed."
  type        = string
}

variable "project_name" {
  description = "The name of the project."
  type        = string
}

variable "table_arn" {
  description = "The ARN of the DynamoDB table."
  type        = string
}

variable "identity_pool_id" {
  description = "The ID of the Cognito Identity Pool to attach roles to."
  type        = string
}


output "lambda_role_arn" {
  value = aws_iam_role.lambda_exec_role.arn
}

