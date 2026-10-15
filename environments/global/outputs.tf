output "github_oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider."
  value       = module.github_oidc.oidc_provider_arn
}

output "deploy_role_arns" {
  description = "IAM roles the quakecstudio/site workflows assume, by GitHub Environment."
  value       = module.github_oidc.role_arns
}
