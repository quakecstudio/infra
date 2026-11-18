output "repositories" {
  description = "Managed repositories and their numeric IDs."
  value       = { for k, m in module.repository : m.full_name => m.repo_id }
}

output "packages_gpg_public_key" {
  description = "Armored public half of the packages.quakecstudio.com signing key, published as gpg/quakecstudio.asc in quakecstudio/packages."
  value       = gpg_key_pair.packages.public_key
}

output "packages_gpg_fingerprint" {
  description = "Fingerprint of the packages.quakecstudio.com signing key."
  value       = gpg_key_pair.packages.fingerprint
}
