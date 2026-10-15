data "archive_file" "function" {
  type        = "zip"
  source_file = "${path.module}/src/index.mjs"
  output_path = "${path.module}/.build/visit-counter.zip"
}

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "function" {
  name               = "${var.name}-visit-counter"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = var.tags
}

data "aws_iam_policy_document" "function" {
  statement {
    sid       = "Counter"
    actions   = ["dynamodb:GetItem", "dynamodb:UpdateItem"]
    resources = [aws_dynamodb_table.counter.arn]
  }

  statement {
    sid       = "Logs"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.function.arn}:*"]
  }
}

resource "aws_iam_role_policy" "function" {
  name   = "visit-counter"
  role   = aws_iam_role.function.id
  policy = data.aws_iam_policy_document.function.json
}

resource "aws_cloudwatch_log_group" "function" {
  name              = "/aws/lambda/${var.name}-visit-counter"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_lambda_function" "counter" {
  function_name    = "${var.name}-visit-counter"
  description      = "Visitor counter for ${var.name}"
  role             = aws_iam_role.function.arn
  runtime          = "nodejs22.x"
  architectures    = ["arm64"]
  handler          = "index.handler"
  filename         = data.archive_file.function.output_path
  source_code_hash = data.archive_file.function.output_base64sha256
  memory_size      = 128
  timeout          = 5

  reserved_concurrent_executions = var.reserved_concurrency

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.counter.name
    }
  }

  logging_config {
    log_format = "Text"
    log_group  = aws_cloudwatch_log_group.function.name
  }

  tags = var.tags

  depends_on = [aws_iam_role_policy.function]
}

# IAM-authenticated: only CloudFront (signing through origin access control)
# can call it. The URL is never used directly.
resource "aws_lambda_function_url" "counter" {
  function_name      = aws_lambda_function.counter.function_name
  authorization_type = "AWS_IAM"
}
