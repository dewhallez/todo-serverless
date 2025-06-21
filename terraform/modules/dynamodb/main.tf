# modules/dynamodb/main.tf

resource "aws_dynamodb_table" "todo_table" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST" # On-demand capacity
  hash_key     = "id"              # Primary key

  attribute {
    name = "id"
    type = "S" # String type
  }

  tags = {
    Environment = "production"
    Project     = var.project_name
  }
}

output "table_name" {
  value = aws_dynamodb_table.todo_table.name
}

output "table_arn" {
  value = aws_dynamodb_table.todo_table.arn
}

variable "table_name" {
  description = "The name of the DynamoDB table"
  type        = string
}

variable "project_name" {
  description = "The name of the project"
  type        = string
}
