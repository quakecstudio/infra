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
  value       = module.deploy_role.role_arn
}

output "github_oidc_provider_arn" {
  description = "GitHub Actions OIDC provider ARN (reuse in other environments in the same account)."
  value       = module.deploy_role.oidc_provider_arn
}

output "site_url" {
  description = "Public URL of the site (GitHub variable SITE_URL)."
  value       = module.site.site_url
}
