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
output "frontend_website_url" {
  description = "The URL of the S3 static website hosting the frontend."
  value       = "http://${module.s3_frontend.website_endpoint}" # S3 website endpoints are HTTP by default
}

output "frontend_s3_bucket_name" {
  description = "The name of the S3 bucket hosting the frontend."
  value       = module.s3_frontend.bucket_name
}




