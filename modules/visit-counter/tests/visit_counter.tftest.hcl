# Plan-only tests against a mocked AWS provider: no credentials needed.
#   terraform init && terraform test

mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{}"
    }
  }

  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/quakecstudio-test-visit-counter"
    }
  }

  mock_resource "aws_cloudwatch_log_group" {
    defaults = {
      arn = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/lambda/quakecstudio-test-visit-counter"
    }
  }

  mock_resource "aws_dynamodb_table" {
    defaults = {
      arn = "arn:aws:dynamodb:us-east-1:123456789012:table/quakecstudio-test-visit-counter"
    }
  }

  mock_resource "aws_lambda_function_url" {
    defaults = {
      function_url = "https://abc123.lambda-url.us-east-1.on.aws/"
    }
  }
}

variables {
  name = "quakecstudio-test"
}

run "defaults" {
  command = apply

  assert {
    condition     = aws_lambda_function.counter.reserved_concurrent_executions == 5
    error_message = "Concurrency should be capped at 5."
  }

  assert {
    condition     = aws_lambda_function_url.counter.authorization_type == "AWS_IAM"
    error_message = "Function URL must require IAM auth."
  }

  assert {
    condition     = output.function_url_domain_name == "abc123.lambda-url.us-east-1.on.aws"
    error_message = "Origin hostname should be the bare function URL host."
  }
}
