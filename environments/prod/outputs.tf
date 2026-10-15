output "aws_region" {
  description = "Region of the site bucket (GitHub variable AWS_REGION)."
  value       = var.aws_region
}

output "bucket_name" {
  description = "Site bucket (GitHub variable SITE_BUCKET)."
  value       = module.site.bucket_name
}

output "distribution_id" {
  description = "CloudFront distribution ID (GitHub variable CLOUDFRONT_DISTRIBUTION_ID)."
  value       = module.site.distribution_id
}

output "deploy_role_arn" {
  description = "IAM role for GitHub Actions (GitHub variable AWS_DEPLOY_ROLE_ARN)."
  value       = data.aws_iam_role.deploy.arn
}

output "site_url" {
  description = "Public URL of the site (GitHub variable SITE_URL)."
  value       = module.site.site_url
}
