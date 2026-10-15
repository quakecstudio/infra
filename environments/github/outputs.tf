output "repositories" {
  description = "Managed repositories and their numeric IDs."
  value       = { for k, m in module.repository : m.full_name => m.repo_id }
}
