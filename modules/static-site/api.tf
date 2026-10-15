# Optional Lambda function URL origin for /api/*.

locals {
  api_enabled   = var.api_origin != null
  api_origin_id = "lambda-api"
}

data "aws_cloudfront_cache_policy" "caching_disabled" {
  count = local.api_enabled ? 1 : 0
  name  = "Managed-CachingDisabled"
}

# Forwards everything except Host, which must be the function URL's own.
data "aws_cloudfront_origin_request_policy" "all_viewer_except_host" {
  count = local.api_enabled ? 1 : 0
  name  = "Managed-AllViewerExceptHostHeader"
}

resource "aws_cloudfront_origin_access_control" "api" {
  count = local.api_enabled ? 1 : 0

  name                              = "${var.name}-api"
  description                       = "Lambda function URL access for ${var.name}"
  origin_access_control_origin_type = "lambda"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Function URLs need both permissions for CloudFront to invoke them.
resource "aws_lambda_permission" "api_url" {
  count = local.api_enabled ? 1 : 0

  statement_id           = "AllowCloudFrontInvokeFunctionUrl"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = var.api_origin.function_name
  function_url_auth_type = "AWS_IAM"
  principal              = "cloudfront.amazonaws.com"
  source_arn             = aws_cloudfront_distribution.site.arn
}

resource "aws_lambda_permission" "api_invoke" {
  count = local.api_enabled ? 1 : 0

  statement_id             = "AllowCloudFrontInvokeFunction"
  action                   = "lambda:InvokeFunction"
  function_name            = var.api_origin.function_name
  invoked_via_function_url = true
  principal                = "cloudfront.amazonaws.com"
  source_arn               = aws_cloudfront_distribution.site.arn
}
