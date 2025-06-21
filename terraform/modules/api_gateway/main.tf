# modules/api_gateway/main.tf

resource "aws_api_gateway_rest_api" "todo_api" {
  name        = "${var.project_name}-api"
  description = "API Gateway for the serverless To-Do application with Cognito authentication"
}

resource "aws_api_gateway_resource" "todos_resource" {
  rest_api_id = aws_api_gateway_rest_api.todo_api.id
  parent_id   = aws_api_gateway_rest_api.todo_api.root_resource_id
  path_part   = "todos"
}

resource "aws_api_gateway_resource" "todo_id_resource" {
  rest_api_id = aws_api_gateway_rest_api.todo_api.id
  parent_id   = aws_api_gateway_resource.todos_resource.id
  path_part   = "{id}"
}

# Cognito User Pool Authorizer
resource "aws_api_gateway_authorizer" "cognito_authorizer" {
  name                   = "${var.project_name}-cognito-authorizer"
  type                   = "COGNITO_USER_POOLS"
  rest_api_id            = aws_api_gateway_rest_api.todo_api.id
  provider_arns          = [var.user_pool_arn] # Reference the User Pool ARN
  identity_source        = "method.request.header.Authorization" # Token is in Authorization header
}

# --- Common Method & Integration for POST, GET /todos ---
# We'll define a reusable method/integration block for the /todos path that uses the authorizer.
# This makes it cleaner for multiple methods on the same resource.

# Define methods with Authorizer
# POST /todos (Create Todo)
resource "aws_api_gateway_method" "create_todo_method" {
  rest_api_id   = aws_api_gateway_rest_api.todo_api.id
  resource_id   = aws_api_gateway_resource.todos_resource.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id
}

resource "aws_api_gateway_integration" "create_todo_integration" {
  rest_api_id             = aws_api_gateway_rest_api.todo_api.id
  resource_id             = aws_api_gateway_resource.todos_resource.id
  http_method             = aws_api_gateway_method.create_todo_method.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = var.lambda_invoke_arn
}

# GET /todos (Get All Todos)
resource "aws_api_gateway_method" "get_all_todos_method" {
  rest_api_id   = aws_api_gateway_rest_api.todo_api.id
  resource_id   = aws_api_gateway_resource.todos_resource.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id
}

resource "aws_api_gateway_integration" "get_all_todos_integration" {
  rest_api_id             = aws_api_gateway_rest_api.todo_api.id
  resource_id             = aws_api_gateway_resource.todos_resource.id
  http_method             = aws_api_gateway_method.get_all_todos_method.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = var.lambda_invoke_arn
}

# OPTIONS /todos (CORS Preflight)
resource "aws_api_gateway_method" "options_todos_method" {
  rest_api_id   = aws_api_gateway_rest_api.todo_api.id
  resource_id   = aws_api_gateway_resource.todos_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE" # OPTIONS requests do not require authorization
}

resource "aws_api_gateway_integration" "options_todos_integration" {
  rest_api_id             = aws_api_gateway_rest_api.todo_api.id
  resource_id             = aws_api_gateway_resource.todos_resource.id
  http_method             = aws_api_gateway_method.options_todos_method.http_method
  type                    = "MOCK" # Use MOCK integration for OPTIONS
  request_templates = {
    "application/json" = "{}"
  }
}

resource "aws_api_gateway_method_response" "options_todos_response_200" {
  rest_api_id = aws_api_gateway_rest_api.todo_api.id
  resource_id = aws_api_gateway_resource.todos_resource.id
  http_method = aws_api_gateway_method.options_todos_method.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "options_todos_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.todo_api.id
  resource_id = aws_api_gateway_resource.todos_resource.id
  http_method = aws_api_gateway_method.options_todos_method.http_method
  status_code = aws_api_gateway_method_response.options_todos_response_200.status_code

  response_templates = {
    "application/json" = ""
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'" # Or specific domains: "'https://your-frontend-domain.com'"
  }
  depends_on = [aws_api_gateway_method.options_todos_method]
}


# --- Methods and Integrations for /todos/{id} ---

# GET /todos/{id} (Get Todo by ID)
resource "aws_api_gateway_method" "get_todo_by_id_method" {
  rest_api_id   = aws_api_gateway_rest_api.todo_api.id
  resource_id   = aws_api_gateway_resource.todo_id_resource.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id
  request_parameters = {
    "method.request.path.id" = true
  }
}

resource "aws_api_gateway_integration" "get_todo_by_id_integration" {
  rest_api_id             = aws_api_gateway_rest_api.todo_api.id
  resource_id             = aws_api_gateway_resource.todo_id_resource.id
  http_method             = aws_api_gateway_method.get_todo_by_id_method.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = var.lambda_invoke_arn
  request_parameters = {
    "integration.request.path.id" = "method.request.path.id" # Map path parameter
  }
}

# PUT /todos/{id} (Update Todo)
resource "aws_api_gateway_method" "update_todo_method" {
  rest_api_id   = aws_api_gateway_rest_api.todo_api.id
  resource_id   = aws_api_gateway_resource.todo_id_resource.id
  http_method   = "PUT"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id
  request_parameters = {
    "method.request.path.id" = true
  }
}

resource "aws_api_gateway_integration" "update_todo_integration" {
  rest_api_id             = aws_api_gateway_rest_api.todo_api.id
  resource_id             = aws_api_gateway_resource.todo_id_resource.id
  http_method             = aws_api_gateway_method.update_todo_method.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = var.lambda_invoke_arn
  request_parameters = {
    "integration.request.path.id" = "method.request.path.id"
  }
}

# DELETE /todos/{id} (Delete Todo)
resource "aws_api_gateway_method" "delete_todo_method" {
  rest_api_id   = aws_api_gateway_rest_api.todo_api.id
  resource_id   = aws_api_gateway_resource.todo_id_resource.id
  http_method   = "DELETE"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id
  request_parameters = {
    "method.request.path.id" = true
  }
}

resource "aws_api_gateway_integration" "delete_todo_integration" {
  rest_api_id             = aws_api_gateway_rest_api.todo_api.id
  resource_id             = aws_api_gateway_resource.todo_id_resource.id
  http_method             = aws_api_gateway_method.delete_todo_method.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = var.lambda_invoke_arn
  request_parameters = {
    "integration.request.path.id" = "method.request.path.id"
  }
}

# OPTIONS /todos/{id} (CORS Preflight for specific ID)
resource "aws_api_gateway_method" "options_todo_id_method" {
  rest_api_id   = aws_api_gateway_rest_api.todo_api.id
  resource_id   = aws_api_gateway_resource.todo_id_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_todo_id_integration" {
  rest_api_id             = aws_api_gateway_rest_api.todo_api.id
  resource_id             = aws_api_gateway_resource.todo_id_resource.id
  http_method             = aws_api_gateway_method.options_todo_id_method.http_method
  type                    = "MOCK"
  request_templates = {
    "application/json" = "{}"
  }
}

resource "aws_api_gateway_method_response" "options_todo_id_response_200" {
  rest_api_id = aws_api_gateway_rest_api.todo_api.id
  resource_id = aws_api_gateway_resource.todo_id_resource.id
  http_method = aws_api_gateway_method.options_todo_id_method.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "options_todo_id_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.todo_api.id
  resource_id = aws_api_gateway_resource.todo_id_resource.id
  http_method = aws_api_gateway_method.options_todo_id_method.http_method
  status_code = aws_api_gateway_method_response.options_todo_id_response_200.status_code

  response_templates = {
    "application/json" = ""
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'" # Or specific domains
  }
  depends_on = [aws_api_gateway_method.options_todo_id_method]
}


# API Gateway Deployment
resource "aws_api_gateway_deployment" "todo_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.todo_api.id
  # Triggers redeployment when any method or integration changes
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_integration.create_todo_integration.id,
      aws_api_gateway_integration.get_all_todos_integration.id,
      aws_api_gateway_integration.get_todo_by_id_integration.id,
      aws_api_gateway_integration.update_todo_integration.id,
      aws_api_gateway_integration.delete_todo_integration.id,
      aws_api_gateway_integration.options_todos_integration.id, # Add CORS integration to trigger redeployment
      aws_api_gateway_integration.options_todo_id_integration.id,
    ]))
  }
  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway Stage
resource "aws_api_gateway_stage" "todo_api_stage" {
  deployment_id = aws_api_gateway_deployment.todo_api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.todo_api.id
  stage_name    = "prod" # Production stage
}

# Permission for API Gateway to invoke Lambda function
resource "aws_lambda_permission" "apigw_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_arn
  principal     = "apigateway.amazonaws.com"
  # The "/*/*" part is important to allow invocation from any method and resource path
  source_arn = "${aws_api_gateway_rest_api.todo_api.execution_arn}/*/*"
}

output "api_gateway_endpoint" {
  value = "${aws_api_gateway_deployment.todo_api_deployment.invoke_url}/${aws_api_gateway_stage.todo_api_stage.stage_name}/todos"
}

variable "project_name" {
  description = "The name of the project."
  type        = string
}

variable "lambda_invoke_arn" {
  description = "The invoke ARN of the Lambda function."
  type        = string
}

variable "lambda_arn" {
  description = "The ARN of the Lambda function."
  type        = string
}

variable "user_pool_arn" {
  description = "The ARN of the Cognito User Pool for the authorizer."
  type        = string
}
