import json
import os
import boto3
import uuid
import datetime

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')
# Get table name from environment variables
TABLE_NAME = os.environ.get('TABLE_NAME')
table = dynamodb.Table(TABLE_NAME)

def lambda_handler(event, context):
    """
    Main handler for AWS Lambda requests.
    Routes requests based on HTTP method and path.
    """
    print(f"Received event: {json.dumps(event)}")

    http_method = event.get('httpMethod')
    path = event.get('path')

    if http_method == 'POST' and path == '/todos':
        return create_todo(event)
    elif http_method == 'GET' and path == '/todos':
        return get_all_todos()
    elif http_method == 'GET' and path.startswith('/todos/'):
        return get_todo_by_id(event)
    elif http_method == 'PUT' and path.startswith('/todos/'):
        return update_todo(event)
    elif http_method == 'DELETE' and path.startswith('/todos/'):
        return delete_todo(event)
    else:
        return {
            'statusCode': 404,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*' # Required for CORS
            },
            'body': json.dumps({'message': 'Not Found'})
        }

def create_todo(event):
    """
    Creates a new To-Do item.
    Expects a JSON body with a 'task' field.
    """
    try:
        body = json.loads(event.get('body', '{}'))
        task = body.get('task')

        if not task:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'message': 'Task field is required'})
            }

        todo_id = str(uuid.uuid4())
        timestamp = datetime.datetime.now().isoformat()

        item = {
            'id': todo_id,
            'task': task,
            'completed': False,
            'createdAt': timestamp,
            'updatedAt': timestamp
        }

        table.put_item(Item=item)

        return {
            'statusCode': 201,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps(item)
        }
    except json.JSONDecodeError:
        return {
            'statusCode': 400,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'message': 'Invalid JSON body'})
        }
    except Exception as e:
        print(f"Error creating todo: {e}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'message': 'Could not create todo', 'error': str(e)})
        }

def get_all_todos():
    """
    Retrieves all To-Do items.
    """
    try:
        response = table.scan() # Scan operation can be inefficient for large tables
        todos = response.get('Items', [])

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps(todos)
        }
    except Exception as e:
        print(f"Error getting all todos: {e}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'message': 'Could not retrieve todos', 'error': str(e)})
        }

def get_todo_by_id(event):
    """
    Retrieves a single To-Do item by its ID.
    The ID is extracted from the path parameters.
    """
    try:
        todo_id = event['pathParameters']['id']
        response = table.get_item(Key={'id': todo_id})
        item = response.get('Item')

        if item:
            return {
                'statusCode': 200,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps(item)
            }
        else:
            return {
                'statusCode': 404,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'message': 'To-Do item not found'})
            }
    except KeyError:
        return {
            'statusCode': 400,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'message': 'To-Do ID missing from path'})
        }
    except Exception as e:
        print(f"Error getting todo by ID: {e}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'message': 'Could not retrieve todo', 'error': str(e)})
        }

def update_todo(event):
    """
    Updates an existing To-Do item by its ID.
    Expects a JSON body with 'task' and/or 'completed' fields.
    """
    try:
        todo_id = event['pathParameters']['id']
        body = json.loads(event.get('body', '{}'))
        task = body.get('task')
        completed = body.get('completed') # This can be boolean or None

        if task is None and completed is None:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'message': 'No update fields provided (task or completed)'})
            }

        update_expression_parts = []
        expression_attribute_values = {}
        expression_attribute_names = {}
        timestamp = datetime.datetime.now().isoformat()

        # Always update 'updatedAt'
        update_expression_parts.append('#ua = :updatedAt')
        expression_attribute_names['#ua'] = 'updatedAt'
        expression_attribute_values[':updatedAt'] = timestamp

        if task is not None:
            update_expression_parts.append('#t = :task')
            expression_attribute_names['#t'] = 'task'
            expression_attribute_values[':task'] = task
        if completed is not None:
            # Ensure 'completed' is a boolean
            if not isinstance(completed, bool):
                return {
                    'statusCode': 400,
                    'headers': {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*'
                    },
                    'body': json.dumps({'message': 'Completed field must be a boolean'})
                }
            update_expression_parts.append('#c = :completed')
            expression_attribute_names['#c'] = 'completed'
            expression_attribute_values[':completed'] = completed

        update_expression = "SET " + ", ".join(update_expression_parts)

        response = table.update_item(
            Key={'id': todo_id},
            UpdateExpression=update_expression,
            ExpressionAttributeNames=expression_attribute_names,
            ExpressionAttributeValues=expression_attribute_values,
            ReturnValues='ALL_NEW' # Returns the updated item
        )

        updated_item = response.get('Attributes')
        if updated_item:
            return {
                'statusCode': 200,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps(updated_item)
            }
        else:
            return {
                'statusCode': 404,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'message': 'To-Do item not found'})
            }
    except KeyError:
        return {
            'statusCode': 400,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'message': 'To-Do ID missing from path'})
        }
    except json.JSONDecodeError:
        return {
            'statusCode': 400,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'message': 'Invalid JSON body'})
        }
    except Exception as e:
        print(f"Error updating todo: {e}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'message': 'Could not update todo', 'error': str(e)})
        }

def delete_todo(event):
    """
    Deletes a To-Do item by its ID.
    The ID is extracted from the path parameters.
    """
    try:
        todo_id = event['pathParameters']['id']
        response = table.delete_item(
            Key={'id': todo_id},
            ReturnValues='ALL_OLD' # Returns the deleted item
        )
        deleted_item = response.get('Attributes')

        if deleted_item:
            return {
                'statusCode': 200,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'message': 'To-Do item deleted successfully', 'deletedItem': deleted_item})
            }
        else:
            return {
                'statusCode': 404,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'message': 'To-Do item not found'})
            }
    except KeyError:
        return {
            'statusCode': 400,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'message': 'To-Do ID missing from path'})
        }
    except Exception as e:
        print(f"Error deleting todo: {e}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'message': 'Could not delete todo', 'error': str(e)})
        }

