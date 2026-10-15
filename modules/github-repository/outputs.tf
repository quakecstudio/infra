output "name" {
  description = "Repository name."
  value       = github_repository.this.name
}

output "full_name" {
  description = "owner/name."
  value       = github_repository.this.full_name
}

output "repo_id" {
  description = "Numeric repository ID."
  value       = github_repository.this.repo_id
}
