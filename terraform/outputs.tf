# outputs.tf

output "api_gateway_endpoint" {
  description = "The base URL for the API Gateway endpoint."
  value       = module.api_gateway.api_gateway_endpoint
}

output "dynamodb_table_name_output" {
  description = "The name of the DynamoDB table."
  value       = module.dynamodb_table.table_name
}

output "lambda_function_name_output" {
  description = "The name of the Lambda function."
  value       = module.lambda_function.lambda_function_name
}

output "lambda_function_arn_output" {
  description = "The ARN of the Lambda function."
  value       = module.lambda_function.lambda_function_arn
}
output "lambda_role_arn_output" {
  description = "The ARN of the IAM role associated with the Lambda function."
  value       = module.lambda_iam.lambda_role_arn
}
output "dynamodb_table_arn_output" {
  description = "The ARN of the DynamoDB table."
  value       = module.dynamodb_table.table_arn
}
output "api_gateway_id_output" {
  description = "The ID of the API Gateway."
  value       = module.api_gateway.api_gateway_id
}
output "lambda_invoke_arn_output" {
  description = "The ARN for invoking the Lambda function."
  value       = module.lambda_function.lambda_invoke_arn
}
output "lambda_function_environment_variables_output" {
  description = "The environment variables for the Lambda function."
  value       = module.lambda_function.lambda_function_environment_variables
}
output "aws_region_output" {
  description = "The AWS region where resources are deployed."
  value       = var.aws_region
}
output "aws_account_id_output" {
  description = "The AWS account ID where resources are deployed."
  value       = var.aws_account_id
}
output "lambda_function_memory_size_output" {
  description = "The memory size allocated to the Lambda function in MB."
  value       = module.lambda_function.lambda_function_memory_size
}
output "lambda_function_timeout_output" {
  description = "The timeout for the Lambda function in seconds."
  value       = module.lambda_function.lambda_function_timeout
}
output "lambda_function_zip_path_output" {
  description = "The path to the Lambda function ZIP file."
  value       = module.lambda_function.lambda_zip_path
}
output "lambda_function_handler_output" {
  description = "The handler function for the Lambda function."
  value       = module.lambda_function.lambda_handler
}
output "lambda_function_runtime_output" {
  description = "The runtime environment for the Lambda function."
  value       = module.lambda_function.lambda_runtime
}
output "lambda_function_invoke_arn_output" {
  description = "The ARN for invoking the Lambda function."
  value       = module.lambda_function.lambda_invoke_arn
}
output "lambda_function_environment_variables_map_output" {
  description = "The environment variables for the Lambda function as a map."
  value       = module.lambda_function.lambda_function_environment_variables_map
}
