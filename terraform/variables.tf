# variables.tf

variable "aws_region" {
  description = "The AWS region to deploy resources to."
  type        = string
  default     = "us-east-1" # You can change this to your desired region
}
# Add your variable declarations here
variable "aws_account_id" {
  description = "The AWS account ID where resources are deployed."
  type        = string
}

variable "project_name" {
  description = "A unique name for your project, used for resource naming."
  type        = string
  default     = "serverless-todo-app"
}

variable "dynamodb_table_name" {
  description = "The name of the DynamoDB table."
  type        = string
  default     = "MyServerlessTodoTable" # Changed name to avoid conflict with SAM
}

variable "lambda_handler" {
  description = "The handler function for the Lambda (e.g., lambda_function.lambda_handler)."
  type        = string
  default     = "lambda_function.lambda_handler"
}

variable "lambda_runtime" {
  description = "The runtime environment for the Lambda function (e.g., python3.9)."
  type        = string
  default     = "python3.12" # Updated to the latest Python version
}

variable "lambda_timeout" {
  description = "The maximum execution time for the Lambda function in seconds."
  type        = number
  default     = 30
}

variable "lambda_memory_size" {
  description = "The amount of memory allocated to the Lambda function in MB."
  type        = number
  default     = 128
}
variable "lambda_invoke_arn" {
  description = "The ARN for invoking the Lambda function."
  type        = string
}
variable "lambda_function_arn" {
  description = "The ARN of the Lambda function."
  type        = string
}
variable "lambda_function_name" {
  description = "The name of the Lambda function."
  type        = string
}
variable "lambda_function_environment_variables" {
  description = "Environment variables for the Lambda function as a map."
  type        = map(string)
  default     = {}
}
variable "lambda_zip_path" {
  description = "The path to the Lambda function ZIP file."
  type        = string
  default     = "lambda_package.zip" # Default to the output path of the archive_file data source
}
variable "identity_pool_id" {
  description = "The Cognito Identity Pool ID"
  type        = string
}

variable "user_pool_id" {
  description = "The Cognito User Pool ID"
  type        = string
}
variable "user_pool_client_id" {
  description = "The Cognito User Pool Client ID"
  type        = string
}
variable "identity_pool_name" {
  description = "The name of the Cognito Identity Pool"
  type        = string
  default     = "MyIdentityPool"
}
variable "user_pool_name" {
  description = "The name of the Cognito User Pool"
  type        = string
  default     = "MyUserPool"
}
variable "user_pool_client_name" {
  description = "The name of the Cognito User Pool Client"
  type        = string
  default     = "MyUserPoolClient"
}
variable "cognito_user_pool_domain" {
  description = "The domain for the Cognito User Pool"
  type        = string
  default     = "myuserpooldomain" # Change this to your desired domain
}
variable "cognito_user_pool_email_verification_subject" {
  description = "The subject for the Cognito User Pool email verification"
  type        = string
  default     = "Verify your email"
}
variable "cognito_user_pool_email_verification_message" {
  description = "The message for the Cognito User Pool email verification"
  type        = string
  default     = "Please verify your email by clicking the link below."
}
variable "cognito_user_pool_sms_verification_message" {
  description = "The message for the Cognito User Pool SMS verification"
  type        = string
  default     = "Your verification code is {####}."
}
variable "cognito_user_pool_lambda_trigger_pre_sign_up" {
  description = "The ARN of the Lambda function to trigger on pre-sign-up events"
  type        = string
  default     = "" # Set to empty string if no Lambda function is used
}
variable "cognito_user_pool_lambda_trigger_post_confirmation" {
  description = "The ARN of the Lambda function to trigger on post-confirmation events"
  type        = string
  default     = "" # Set to empty string if no Lambda function is used
}
variable "cognito_user_pool_lambda_trigger_pre_authentication" {
  description = "The ARN of the Lambda function to trigger on pre-authentication events"
  type        = string
  default     = "" # Set to empty string if no Lambda function is used
}