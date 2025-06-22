import pytest
from unittest.mock import patch, MagicMock
from backend import main
import json

@pytest.fixture(autouse=True)
def patch_table(monkeypatch: pytest.MonkeyPatch):
    # Patch the DynamoDB table used in main.py
    mock_table = MagicMock()
    monkeypatch.setattr(main, "table", mock_table)
    return mock_table

def test_create_todo_success(patch_table: MagicMock):
    event = {
        "body": json.dumps({"task": "Test task"}),
        "userId": "user-123"
    }
    response = main.create_todo(event)
    assert response["statusCode"] == 201
    body = json.loads(response["body"])
    assert body["task"] == "Test task"
    assert body["completed"] is False
    assert body["userId"] == "user-123"
    patch_table.put_item.assert_called_once()

def test_create_todo_missing_task(patch_table: MagicMock):
    event = {
        "body": json.dumps({}),
        "userId": "user-123"
    }
    response = main.create_todo(event)
    assert response["statusCode"] == 400
    assert "Task field is required" in response["body"]

def test_create_todo_invalid_json(patch_table: MagicMock):
    event = {
        "body": "{invalid json",
        "userId": "user-123"
    }
    response = main.create_todo(event)
    assert response["statusCode"] == 400
    assert "Invalid JSON body" in response["body"]

def test_get_all_todos_success(patch_table: MagicMock):
    patch_table.scan.return_value = {"Items": [{"id": "1", "task": "A", "userId": "user-123"}]}
    event = {"userId": "user-123"}
    response = main.get_all_todos(event)
    assert response["statusCode"] == 200
    todos = json.loads(response["body"])
    assert isinstance(todos, list)
    assert todos[0]["userId"] == "user-123"

def test_get_all_todos_unauthenticated(patch_table: MagicMock):
    event = {"userId": None}
    response = main.get_all_todos(event)
    assert response["statusCode"] == 401
    assert "Authentication required" in response["body"]