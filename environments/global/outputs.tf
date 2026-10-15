output "github_oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider."
  value       = module.github_oidc.oidc_provider_arn
}

output "deploy_role_arns" {
  description = "IAM roles the quakecstudio/site workflows assume, by GitHub Environment."
  value       = module.github_oidc.role_arns
}

output "hosted_zone_id" {
  description = "Route 53 hosted zone for quakecstudio.com."
  value       = aws_route53_zone.site.zone_id
}

output "name_servers" {
  description = "Name servers to delegate quakecstudio.com to at the registrar."
  value       = aws_route53_zone.site.name_servers
}
