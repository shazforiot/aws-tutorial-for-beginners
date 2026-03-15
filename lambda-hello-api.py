"""
AWS for Beginners 2026 — Lambda Function Demo
==============================================
This is the complete Lambda function to deploy via AWS Console or CLI.

HOW TO DEPLOY:
  Option A — AWS Console:
    1. Go to Lambda → Create Function → Author from scratch
    2. Function name: hello-api-2026
    3. Runtime: Python 3.12
    4. Paste this code in the inline editor
    5. Click Deploy
    6. Test with the sample event below

  Option B — AWS CLI:
    1. zip lambda.zip lambda-hello-api.py
    2. aws lambda create-function \
         --function-name hello-api-2026 \
         --runtime python3.12 \
         --handler lambda-hello-api.lambda_handler \
         --role arn:aws:iam::YOUR_ACCOUNT_ID:role/lambda-basic-role \
         --zip-file fileb://lambda.zip

SAMPLE TEST EVENT (paste in Lambda console Test tab):
{
  "name": "AWS Learner",
  "action": "greet"
}
"""

import json
import boto3
import os
from datetime import datetime, timezone


def lambda_handler(event, context):
    """
    Main Lambda handler — entry point for all invocations.

    Parameters:
      event   : dict — incoming data (from API Gateway, S3, EventBridge, etc.)
      context : LambdaContext — runtime info (function name, remaining time, etc.)

    Returns:
      dict — HTTP response with statusCode and JSON body
    """

    print(f"Event received: {json.dumps(event)}")
    print(f"Function name: {context.function_name}")
    print(f"Remaining time: {context.get_remaining_time_in_millis()}ms")

    # Parse the incoming action
    action = event.get("action", "greet")
    name = event.get("name", "World")

    if action == "greet":
        result = handle_greet(name)
    elif action == "info":
        result = handle_info(context)
    elif action == "s3-list":
        result = handle_s3_list(event.get("bucket"))
    else:
        return build_response(400, {"error": f"Unknown action: {action}"})

    return build_response(200, result)


# ── Handlers ──────────────────────────────────────────────────────────────────

def handle_greet(name: str) -> dict:
    """Simple greeting handler."""
    return {
        "message": f"👋 Hello, {name}! Welcome to AWS Lambda — 2026!",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "service": "AWS Lambda",
        "runtime": "Python 3.12",
    }


def handle_info(context) -> dict:
    """Return Lambda runtime information."""
    return {
        "function_name": context.function_name,
        "function_version": context.function_version,
        "memory_limit_mb": context.memory_limit_in_mb,
        "aws_request_id": context.aws_request_id,
        "log_group": context.log_group_name,
        "remaining_time_ms": context.get_remaining_time_in_millis(),
        "region": os.environ.get("AWS_REGION", "unknown"),
    }


def handle_s3_list(bucket_name: str) -> dict:
    """List objects in an S3 bucket (demonstrates Lambda → S3 integration)."""
    if not bucket_name:
        return {"error": "bucket parameter required"}

    s3 = boto3.client("s3")
    try:
        response = s3.list_objects_v2(Bucket=bucket_name, MaxKeys=10)
        objects = [
            {"key": obj["Key"], "size_kb": round(obj["Size"] / 1024, 2)}
            for obj in response.get("Contents", [])
        ]
        return {
            "bucket": bucket_name,
            "object_count": response.get("KeyCount", 0),
            "objects": objects,
        }
    except Exception as e:
        return {"error": str(e)}


# ── Helper ────────────────────────────────────────────────────────────────────

def build_response(status_code: int, body: dict) -> dict:
    """Build a standard API Gateway-compatible HTTP response."""
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",  # Enable CORS
        },
        "body": json.dumps(body, indent=2),
    }


# ── Local testing (not used in Lambda runtime) ────────────────────────────────
if __name__ == "__main__":
    # Simulate a Lambda invocation locally
    class FakeContext:
        function_name = "hello-api-2026"
        function_version = "$LATEST"
        memory_limit_in_mb = 128
        aws_request_id = "local-test-12345"
        log_group_name = "/aws/lambda/hello-api-2026"
        def get_remaining_time_in_millis(self): return 29000

    # Test greet
    event1 = {"action": "greet", "name": "AWS Beginner"}
    print("=== Test 1: Greet ===")
    print(json.dumps(lambda_handler(event1, FakeContext()), indent=2))

    # Test info
    event2 = {"action": "info"}
    print("\n=== Test 2: Info ===")
    print(json.dumps(lambda_handler(event2, FakeContext()), indent=2))
