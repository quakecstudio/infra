output "bucket_name" {
  description = "Name of the S3 bucket holding the package repository."
  value       = aws_s3_bucket.packages.id
}

output "distribution_id" {
  description = "CloudFront distribution ID (for cache invalidations)."
  value       = aws_cloudfront_distribution.packages.id
}

output "publish_role_arn" {
  description = "IAM role the publishing repository's workflow assumes through OIDC."
  value       = aws_iam_role.publish.arn
}
