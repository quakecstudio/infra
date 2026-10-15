output "role_arn" {
  description = "ARN of the deploy role (set as AWS_DEPLOY_ROLE_ARN in GitHub)."
  value       = aws_iam_role.deploy.arn
}

output "oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider in use."
  value       = local.oidc_provider_arn
}
