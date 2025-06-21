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
  default     = "MyServerlessTodoTableTerraform" # Changed name to avoid conflict with SAM
}

variable "lambda_handler" {
  description = "The handler function for the Lambda (e.g., lambda_function.lambda_handler)."
  type        = string
  default     = "lambda_function.lambda_handler"
}

variable "lambda_runtime" {
  description = "The runtime environment for the Lambda function (e.g., python3.9)."
  type        = string
  default     = "python3.9"
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

