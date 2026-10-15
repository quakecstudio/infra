output "oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider."
  value       = aws_iam_openid_connect_provider.github.arn
}

output "role_arns" {
  description = "Deploy role ARNs, by GitHub Environment."
  value       = { for env, role in aws_iam_role.deploy : env => role.arn }
}

output "role_names" {
  description = "Deploy role names, by GitHub Environment."
  value       = { for env, role in aws_iam_role.deploy : env => role.name }
}
