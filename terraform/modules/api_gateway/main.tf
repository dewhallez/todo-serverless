# modules/api_gateway/main.tf

variable "lambda_invoke_arn" {
  description = "The ARN of the Lambda function to be invoked by API Gateway"
  type        = string
}

resource "aws_apigateway_rest_api" "todo_api" {
  name        = "${var.project_name}-api"
  description = "API Gateway for the serverless To-Do application"
}

resource "aws_apigateway_resource" "todos_resource" {
  rest_api_id = aws_apigateway_rest_api.todo_api.id
  parent_id   = aws_apigateway_rest_api.todo_api.root_resource_id
  path_part   = "todos"
}

resource "aws_apigateway_resource" "todo_id_resource" {
  rest_api_id = aws_apigateway_rest_api.todo_api.id
  parent_id   = aws_apigateway_resource.todos_resource.id
  path_part   = "{id}"
}

# --- Methods and Integrations for /todos ---

# POST /todos (Create Todo)
resource "aws_apigateway_method" "create_todo_method" {
  rest_api_id   = aws_apigateway_rest_api.todo_api.id
  resource_id   = aws_apigateway_resource.todos_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_apigateway_integration" "create_todo_integration" {
  rest_api_id             = aws_apigateway_rest_api.todo_api.id
  resource_id             = aws_apigateway_resource.todos_resource.id
  http_method             = aws_apigateway_method.create_todo_method.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST" # Lambda Proxy integration always uses POST
  uri                     = var.lambda_invoke_arn
}

# GET /todos (Get All Todos)
resource "aws_apigateway_method" "get_all_todos_method" {
  rest_api_id   = aws_apigateway_rest_api.todo_api.id
  resource_id   = aws_apigateway_resource.todos_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_apigateway_integration" "get_all_todos_integration" {
  rest_api_id             = aws_apigateway_rest_api.todo_api.id
  resource_id             = aws_apigateway_resource.todos_resource.id
  http_method             = aws_apigateway_method.get_all_todos_method.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = var.lambda_invoke_arn
}

# --- Methods and Integrations for /todos/{id} ---

# GET /todos/{id} (Get Todo by ID)
resource "aws_apigateway_method" "get_todo_by_id_method" {
  rest_api_id   = aws_apigateway_rest_api.todo_api.id
  resource_id   = aws_apigateway_resource.todo_id_resource.id
  http_method   = "GET"
  authorization = "NONE"
  request_parameters = {
    "method.request.path.id" = true
  }
}

resource "aws_apigateway_integration" "get_todo_by_id_integration" {
  rest_api_id             = aws_apigateway_rest_api.todo_api.id
  resource_id             = aws_apigateway_resource.todo_id_resource.id
  http_method             = aws_apigateway_method.get_todo_by_id_method.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = var.lambda_invoke_arn
  request_parameters = {
    "integration.request.path.id" = "method.request.path.id" # Map path parameter
  }
}

# PUT /todos/{id} (Update Todo)
resource "aws_apigateway_method" "update_todo_method" {
  rest_api_id   = aws_apigateway_rest_api.todo_api.id
  resource_id   = aws_apigateway_resource.todo_id_resource.id
  http_method   = "PUT"
  authorization = "NONE"
  request_parameters = {
    "method.request.path.id" = true
  }
}

resource "aws_apigateway_integration" "update_todo_integration" {
  rest_api_id             = aws_apigateway_rest_api.todo_api.id
  resource_id             = aws_apigateway_resource.todo_id_resource.id
  http_method             = aws_apigateway_method.update_todo_method.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = var.lambda_invoke_arn
  request_parameters = {
    "integration.request.path.id" = "method.request.path.id"
  }
}

# DELETE /todos/{id} (Delete Todo)
resource "aws_apigateway_method" "delete_todo_method" {
  rest_api_id   = aws_apigateway_rest_api.todo_api.id
  resource_id   = aws_apigateway_resource.todo_id_resource.id
  http_method   = "DELETE"
  authorization = "NONE"
  request_parameters = {
    "method.request.path.id" = true
  }
}

resource "aws_apigateway_integration" "delete_todo_integration" {
  rest_api_id             = aws_apigateway_rest_api.todo_api.id
  resource_id             = aws_apigateway_resource.todo_id_resource.id
  http_method             = aws_apigateway_method.delete_todo_method.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = var.lambda_invoke_arn
  request_parameters = {
    "integration.request.path.id" = "method.request.path.id"
  }
}

# API Gateway Deployment
resource "aws_apigateway_deployment" "todo_api_deployment" {
  rest_api_id = aws_apigateway_rest_api.todo_api.id
  # Triggers redeployment when any method or integration changes
  triggers = {
    redeployment = sha1(jsonencode([
      aws_apigateway_integration.create_todo_integration.id,
      aws_apigateway_integration.get_all_todos_integration.id,
      aws_apigateway_integration.get_todo_by_id_integration.id,
      aws_apigateway_integration.update_todo_integration.id,
      aws_apigateway_integration.delete_todo_integration.id,
    ]))
  }
  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway Stage
resource "aws_apigateway_stage" "todo_api_stage" {
  deployment_id = aws_apigateway_deployment.todo_api_deployment.id
  rest_api_id   = aws_apigateway_rest_api.todo_api.id
  stage_name    = "prod" # Production stage
}

# Permission for API Gateway to invoke Lambda function
resource "aws_lambda_permission" "apigw_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_invoke_arn
  principal     = "apigateway.amazonaws.com"
  # The "/*/*" part is important to allow invocation from any method and resource path
  source_arn = "${aws_apigateway_rest_api.todo_api.execution_arn}/*/*"
}

output "api_gateway_endpoint" {
  value = "${aws_apigateway_deployment.todo_api_deployment.invoke_url}/${aws_apigateway_stage.todo_api_stage.stage_name}/todos"
}

