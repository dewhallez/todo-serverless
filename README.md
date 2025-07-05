[![Tests](https://github.com/dewhallez/todo-serverless/actions/workflows/python-tests.yml/badge.svg)](https://github.com/dewhallez/todo-serverless/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python](https://img.shields.io/badge/python-3.11-blue.svg)](https://www.python.org/downloads/release/python-311/)
[![AWS](https://img.shields.io/badge/AWS-Serverless-orange)](https://aws.amazon.com/serverless/)
[![Coverage](https://img.shields.io/badge/coverage-passing-brightgreen)](#)

# TodoApp

AWS-powered Todo application. This project demonstrates how to build, deploy, and manage a serverless todo app using AWS services.

## Features

- Add, update, and delete todo items  
- Serverless backend (AWS Lambda, API Gateway, DynamoDB)  
- JavaScript frontend  
- Scalable and cost-effective  
- Infrastructure as Code with Terraform  
- Automated testing with GitHub Actions

## Getting Started

1. **Clone the repository**
    ```sh
    git clone https://github.com/dewhallez/todo-serverless.git
    cd todo-serverless
    ```

2. **Backend Setup**
    - Install Python 3.11+
    - Install dependencies:
      ```sh
      cd backend
      pip install -r requirements.txt
      ```
    - Run tests:
      ```sh
      pytest
      ```

## License

MIT License
