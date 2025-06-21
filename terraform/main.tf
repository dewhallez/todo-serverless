# main.tf

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region # Use the AWS region defined in variables.tf
}

# Reference the DynamoDB table from the dynamodb.tf file
module "dynamodb_table" {
  source     = "./modules/dynamodb"    # Path to the DynamoDB module (assuming it's in a 'modules/dynamodb' directory)
  table_name = var.dynamodb_table_name # Use the table name from variables.tf
  project_name = var.project_name      # Add the required project_name variable
}

# Reference the IAM role and policy for Lambda from iam.tf
module "lambda_iam" {
  source       = "./modules/iam"                 # Path to the IAM module
  project_name = var.project_name                # Use the project name from variables.tf
  table_arn    = module.dynamodb_table.table_arn # Pass the DynamoDB table ARN to the IAM module
  aws_region   = var.aws_region                  # Pass the AWS region variable
  identity_pool_id = var.identity_pool_id        # Pass the required identity pool ID
  aws_account_id   = var.aws_account_id          # Pass the required AWS account ID
}
# Reference the API Gateway from api_gateway.tf
module "api_gateway" {
  source            = "./modules/api_gateway"                  # Path to the API Gateway module
  lambda_invoke_arn = module.lambda_function.lambda_invoke_arn # Pass the Lambda invoke ARN
  lambda_arn        = module.lambda_function.lambda_function_arn # Pass the Lambda function ARN
  user_pool_arn     = module.cognito.user_pool_arn             # Pass the Cognito User Pool ARN
  project_name      = var.project_name                         # Pass the project name
}
# Reference the Lambda function from modules/lambda
module "lambda_function" {
  source = "./modules/lambda" # Path to the Lambda module
  project_name = var.project_name # Use the project name
  lambda_handler = var.lambda_handler # Lambda handler (e.g., "lambda_function.lambda_handler")
  # runtime = var.lambda_runtime # Lambda runtime (e.g., "python3.9") -- Removed because not expected by the module
  lambda_role_arn = module.lambda_iam.lambda_role_arn # Pass the IAM role ARN to the Lambda module
  dynamodb_table_name = var.dynamodb_table_name # Pass the DynamoDB table name as an environment variable
  lambda_timeout = var.lambda_timeout # Pass the Lambda timeout
  lambda_memory_size = var.lambda_memory_size # Pass the Lambda memory size
  lambda_invoke_arn = var.lambda_invoke_arn # Provide the Lambda invoke ARN
  aws_account_id = var.aws_account_id # Provide the AWS account ID
  lambda_function_arn = var.lambda_function_arn # Provide the Lambda function ARN
  lambda_function_name = var.lambda_function_name # Provide the Lambda function name
  lambda_function_environment_variables = var.lambda_function_environment_variables # Provide environment variables as a map
}
# New Cognito module
module "cognito" {
  source = "./modules/cognito" # Path to the new Cognito module
  project_name = var.project_name # Use the project name
}