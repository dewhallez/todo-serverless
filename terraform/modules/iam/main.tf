# modules/iam/main.tf

variable "project_name" {
  description = "The name of the project, used for naming resources"
  type        = string
}

variable "table_arn" {
  description = "The ARN of the DynamoDB table to grant access to"
  type        = string
}

variable "aws_region" {
  description = "The AWS region where resources will be created"
  type        = string
}

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
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-*:*"
      }
    ]
  })
}

data "aws_caller_identity" "current" {} # Used to get the AWS account ID

output "lambda_role_arn" {
  value = aws_iam_role.lambda_exec_role.arn
}

