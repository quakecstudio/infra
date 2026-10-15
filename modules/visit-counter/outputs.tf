output "function_name" {
  description = "Lambda function name."
  value       = aws_lambda_function.counter.function_name
}

output "function_url_domain_name" {
  description = "Hostname of the function URL, for use as a CloudFront origin."
  value       = split("/", aws_lambda_function_url.counter.function_url)[2]
}

output "table_name" {
  description = "DynamoDB table holding the count."
  value       = aws_dynamodb_table.counter.name
}
