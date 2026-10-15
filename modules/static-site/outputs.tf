output "bucket_name" {
  description = "Name of the S3 bucket holding the site content."
  value       = aws_s3_bucket.site.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket holding the site content."
  value       = aws_s3_bucket.site.arn
}

output "distribution_id" {
  description = "CloudFront distribution ID (for cache invalidations)."
  value       = aws_cloudfront_distribution.site.id
}

output "distribution_arn" {
  description = "CloudFront distribution ARN."
  value       = aws_cloudfront_distribution.site.arn
}

output "distribution_domain_name" {
  description = "The *.cloudfront.net hostname of the distribution."
  value       = aws_cloudfront_distribution.site.domain_name
}

output "site_url" {
  description = "Public URL of the site."
  value       = "https://${local.custom_domain ? var.domain_names[0] : aws_cloudfront_distribution.site.domain_name}"
}
