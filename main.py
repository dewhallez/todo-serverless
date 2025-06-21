import json
import os
import boto3
import uuid
import datetime
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')
# Get table name from environment variables
TABLE_NAME = os.environ.get('TABLE_NAME')
table = dynamodb.Table(TABLE_NAME)

def lambda_handler(event, context):
    """
    Main handler for AWS Lambda requests.
    Routes requests based on HTTP method and path.
    Extracts user ID from authenticated requests.
    """
    logger.info(f"Received event: {json.dumps(event)}")

    # Extract user ID from Cognito Authorizer context
    user_id = None
    if event.get('requestContext') and \
       event['requestContext'].get('authorizer') and \
       event['requestContext']['authorizer'].get('claims'):
        user_id = event['requestContext']['authorizer']['claims'].get('sub')
        logger.info(f"Authenticated User ID: {user_id}")
    else:
        logger.info("No authenticated user ID found in event context.")

    http_method = event.get('httpMethod')
    path = event.get('path')

    # Handle CORS preflight OPTIONS requests
    if http_method == 'OPTIONS':
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                'Access-Control-Max-Age': '86400' # Cache preflight for 24 hours
            },
            'body': ''
        }

    # Pass user_id to CRUD functions
    event['userId'] = user_id # Add user ID to event for CRUD functions to use

    if http_method == 'POST' and path == '/todos':
        return create_todo(event)
    elif http_method == 'GET' and path == '/todos':
        return get_all_todos(event)
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
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'message': 'Not Found'})
        }

def create_todo(event):
    """
    Creates a new To-Do item.
    Expects a JSON body with a 'task' field.
    Includes userId for ownership.
    """
    user_id = event.get('userId')
    logger.info(f"Create To-Do for User: {user_id}")
    try:
        body = json.loads(event.get('body', '{}'))
        task = body.get('task')

        if not task:
            logger.warning("Missing 'task' field in create_todo request.")
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
        # Add userId to the item if available. This is crucial for user-specific data.
        if user_id:
            item['userId'] = user_id

        table.put_item(Item=item)
        logger.info(f"Successfully created todo item: {item['id']} for user: {user_id}")

        return {
            'statusCode': 201,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps(item)
        }
    except json.JSONDecodeError:
        logger.error("Invalid JSON body received in create_todo.")
        return {
            'statusCode': 400,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'message': 'Invalid JSON body'})
        }
    except Exception as e:
        logger.exception(f"Error creating todo for user {user_id}: {e}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'message': 'Could not create todo', 'error': str(e)})
        }

def get_all_todos(event):
    """
    Retrieves all To-Do items for the authenticated user.
    Requires userId for filtering.
    Note: A 'scan' without a filter can still fetch all items.
    For production, consider using a GSI on userId and 'query' instead of 'scan'.
    """
    user_id = event.get('userId')
    logger.info(f"Get all To-Dos for User: {user_id}")
    if not user_id:
        logger.warning("Attempted to get all todos without authenticated user ID.")
        return {
            'statusCode': 401,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'message': 'Authentication required to retrieve todos.'})
        }

    try:
        # Example of how you would filter by userId using scan.
        # For large datasets, a Global Secondary Index (GSI) on 'userId' with a 'query' operation would be more efficient.
        response = table.scan(
            FilterExpression=boto3.dynamodb.conditions.Attr('userId').eq(user_id)
        )
        todos = response.get('Items', [])
        logger.info(f"Retrieved {len(todos)} todos for user: {user_id}")

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps(todos)
        }
    except Exception as e:
        logger.exception(f"Error getting all todos for user {user_id}: {e}")
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
    Verifies ownership using userId.
    """
    user_id = event.get('userId')
    todo_id = event['pathParameters']['id']
    logger.info(f"Get To-Do {todo_id} for User: {user_id}")
    if not user_id:
        logger.warning(f"Attempted to get todo {todo_id} without authenticated user ID.")
        return {
            'statusCode': 401,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'message': 'Authentication required to retrieve todo.'})
        }

    try:
        response = table.get_item(Key={'id': todo_id})
        item = response.get('Item')

        if item:
            # Ensure the retrieved item belongs to the authenticated user
            if item.get('userId') == user_id:
                logger.info(f"Retrieved todo {todo_id} for user: {user_id}")
                return {
                    'statusCode': 200,
                    'headers': {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*'
                    },
                    'body': json.dumps(item)
                }
            else:
                logger.warning(f"User {user_id} attempted to access todo {todo_id} owned by another user.")
                return {
                    'statusCode': 403, # Forbidden
                    'headers': {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*'
                    },
                    'body': json.dumps({'message': 'Access denied: To-Do item does not belong to you'})
                }
        else:
            logger.info(f"Todo item {todo_id} not found.")
            return {
                'statusCode': 404,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'message': 'To-Do item not found'})
            }
    except KeyError:
        logger.error("To-Do ID missing from path in get_todo_by_id.")
        return {
            'statusCode': 400,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'message': 'To-Do ID missing from path'})
        }
    except Exception as e:
        logger.exception(f"Error getting todo {todo_id} for user {user_id}: {e}")
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
    Verifies ownership using userId.
    """
    user_id = event.get('userId')
    todo_id = event['pathParameters']['id']
    logger.info(f"Update To-Do {todo_id} for User: {user_id}")
    if not user_id:
        logger.warning(f"Attempted to update todo {todo_id} without authenticated user ID.")
        return {
            'statusCode': 401,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'message': 'Authentication required to update todo.'})
        }

    try:
        body = json.loads(event.get('body', '{}'))
        task = body.get('task')
        completed = body.get('completed') # This can be boolean or None

        if task is None and completed is None:
            logger.warning(f"No update fields provided for todo {todo_id}.")
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'message': 'No update fields provided (task or completed)'})
            }

        # First, get the item to check ownership
        response_get = table.get_item(Key={'id': todo_id})
        existing_item = response_get.get('Item')

        if not existing_item:
            logger.info(f"Todo item {todo_id} not found for update.")
            return {
                'statusCode': 404,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'message': 'To-Do item not found'})
            }

        if existing_item.get('userId') != user_id:
            logger.warning(f"User {user_id} attempted to update todo {todo_id} owned by another user.")
            return {
                'statusCode': 403, # Forbidden
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'message': 'Access denied: To-Do item does not belong to you'})
            }

        update_expression_parts = []
        expression_attribute_values = {}
        expression_attribute_names = {}
        timestamp = datetime.datetime.now().isoformat()

        update_expression_parts.append('#ua = :updatedAt')
        expression_attribute_names['#ua'] = 'updatedAt'
        expression_attribute_values[':updatedAt'] = timestamp

        if task is not None:
            update_expression_parts.append('#t = :task')
            expression_attribute_names['#t'] = 'task'
            expression_attribute_values[':task'] = task
        if completed is not None:
            if not isinstance(completed, bool):
                logger.warning(f"Invalid type for 'completed' field in update_todo: {completed}")
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

        response_update = table.update_item(
            Key={'id': todo_id},
            UpdateExpression=update_expression,
            ExpressionAttributeNames=expression_attribute_names,
            ExpressionAttributeValues=expression_attribute_values,
            ReturnValues='ALL_NEW', # Returns the updated item
            ConditionExpression=boto3.dynamodb.conditions.Attr('userId').eq(user_id) # Ensure ownership on update
        )

        updated_item = response_update.get('Attributes')
        logger.info(f"Successfully updated todo item: {todo_id} for user: {user_id}")
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps(updated_item)
        }
    except KeyError:
        logger.error("To-Do ID missing from path in update_todo.")
        return {
            'statusCode': 400,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'message': 'To-Do ID missing from path'})
        }
    except json.JSONDecodeError:
        logger.error("Invalid JSON body received in update_todo.")
        return {
            'statusCode': 400,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'message': 'Invalid JSON body'})
        }
    except boto3.exceptions.ClientError as e:
        if e.response['Error']['Code'] == 'ConditionalCheckFailedException':
            logger.warning(f"Conditional check failed for todo {todo_id} by user {user_id}. Item not owned or not found.")
            return {
                'statusCode': 403, # Forbidden, or 404 if item didn't exist for user
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'message': 'Access denied or item not found for your user'})
            }
        else:
            logger.exception(f"DynamoDB ClientError updating todo {todo_id} for user {user_id}: {e}")
            return {
                'statusCode': 500,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'message': 'Could not update todo due to DynamoDB error', 'error': str(e)})
            }
    except Exception as e:
        logger.exception(f"Error updating todo {todo_id} for user {user_id}: {e}")
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
    Verifies ownership using userId.
    """
    user_id = event.get('userId')
    todo_id = event['pathParameters']['id']
    logger.info(f"Delete To-Do {todo_id} for User: {user_id}")
    if not user_id:
        logger.warning(f"Attempted to delete todo {todo_id} without authenticated user ID.")
        return {
            'statusCode': 401,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'message': 'Authentication required to delete todo.'})
        }

    try:
        # Check ownership before attempting to delete
        response_get = table.get_item(Key={'id': todo_id})
        existing_item = response_get.get('Item')

        if not existing_item:
            logger.info(f"Todo item {todo_id} not found for deletion.")
            return {
                'statusCode': 404,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'message': 'To-Do item not found'})
            }

        if existing_item.get('userId') != user_id:
            logger.warning(f"User {user_id} attempted to delete todo {todo_id} owned by another user.")
            return {
                'statusCode': 403, # Forbidden
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'message': 'Access denied: To-Do item does not belong to you'})
            }

        response_delete = table.delete_item(
            Key={'id': todo_id},
            ReturnValues='ALL_OLD', # Returns the deleted item
            ConditionExpression=boto3.dynamodb.conditions.Attr('userId').eq(user_id) # Ensure ownership on delete
        )
        deleted_item = response_delete.get('Attributes')

        logger.info(f"Successfully deleted todo item: {todo_id} for user: {user_id}")
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'message': 'To-Do item deleted successfully', 'deletedItem': deleted_item})
        }
    except KeyError:
        logger.error("To-Do ID missing from path in delete_todo.")
        return {
            'statusCode': 400,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'message': 'To-Do ID missing from path'})
        }
    except boto3.exceptions.ClientError as e:
        if e.response['Error']['Code'] == 'ConditionalCheckFailedException':
            logger.warning(f"Conditional check failed for delete todo {todo_id} by user {user_id}. Item not owned or not found.")
            return {
                'statusCode': 403, # Forbidden, or 404 if item didn't exist for user
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'message': 'Access denied or item not found for your user'})
            }
        else:
            logger.exception(f"DynamoDB ClientError deleting todo {todo_id} for user {user_id}: {e}")
            return {
                'statusCode': 500,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'message': 'Could not delete todo due to DynamoDB error', 'error': str(e)})
            }
    except Exception as e:
        logger.exception(f"Error deleting todo {todo_id} for user {user_id}: {e}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'message': 'Could not delete todo', 'error': str(e)})
        }

# Note: Ensure that the Lambda function has the necessary IAM permissions to access DynamoDB.
# The function should have permissions for:
# - dynamodb:PutItem
# - dynamodb:GetItem
# - dynamodb:UpdateItem
# - dynamodb:DeleteItem
# - dynamodb:Scan (if using scan for get_all_todos)
# - dynamodb:Query (if using query for get_all_todos with GSI)


