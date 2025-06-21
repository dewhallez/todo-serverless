# modules/lambda/main.tf

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "../../" # This path assumes lambda_function.py and requirements.txt are in the parent directory of this module
  output_path = "lambda_package.zip" # Output ZIP file name
  excludes    = ["terraform", ".terraform", "*.tf", "*.tfvars", "*.zip", "modules"] # Exclude Terraform files
}

resource "aws_lambda_function" "todo_function" {
  function_name    = "${var.project_name}-function"
  handler          = var.lambda_handler
  runtime          = var.lambda_runtime
  role             = var.lambda_role_arn
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256 # Trigger redeploy on code changes
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_function_memory_size

  environment {
    variables = {
      TABLE_NAME = var.dynamodb_table_name
    }
  }

# depends_on = [
#  aws_cloudwatch_log_group.todo_lambda_log_group # Ensure log group exists before Lambda
# ]

}

resource "aws_cloudwatch_log_group" "todo_lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.todo_function.function_name}"
  retention_in_days = 14 # Retain logs for 14 days
}


output "lambda_arn" {
  value = aws_lambda_function.todo_function.arn
}

output "lambda_invoke_arn" {
  value = aws_lambda_function.todo_function.invoke_arn
}

output "lambda_function_name" {
  value = aws_lambda_function.todo_function.function_name
}

variable "project_name" {
  description = "The name of the project"
  type        = string
}
variable "lambda_handler" {
  description = "The handler for the Lambda function"
  type        = string
  default     = "lambda_function.lambda_handler" # Default to lambda_function.py
}
variable "lambda_runtime" {
  description = "The runtime for the Lambda function"
  type        = string
  default     = "python3.10" # Default to Python 3.10
}
variable "lambda_function_memory_size" {
  description = "The memory size for the Lambda function in MB"
  type        = number
  default     = 128 # Default to 128 MB
}

variable "lambda_timeout" {
  description = "The timeout for the Lambda function in seconds"
  type        = number
  default     = 10 # Default to 10 seconds
}

variable "lambda_role_arn" {
  description = "The ARN of the IAM role for the Lambda function"
  type        = string
}

variable "dynamodb_table_name" {
  description = "The name of the DynamoDB table used by the Lambda function"
  type        = string
}