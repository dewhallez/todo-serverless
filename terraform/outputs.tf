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


