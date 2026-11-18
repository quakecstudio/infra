# Signing key for packages.quakecstudio.com. The editor's release workflow
# signs its RPMs and the APT and YUM/DNF repository metadata with it. Terraform
# generates the key, so its private half exists only in the (encrypted) state
# and the editor's secrets. The public half is the packages_gpg_public_key output, which
# quakecstudio/packages publishes as gpg/quakecstudio.asc.
#
# Changing the identity or the passphrase replaces the key: users would have
# to trust the new public key before they can install or update packages.

resource "random_password" "packages_gpg_passphrase" {
  length  = 32
  special = false
}

resource "gpg_key_pair" "packages" {
  identities = [{
    name  = "QuakeC Studio Packages"
    email = "hello@inbox.quakecstudio.com"
  }]
  passphrase = random_password.packages_gpg_passphrase.result
}

resource "github_actions_secret" "packages_gpg_private_key" {
  repository  = module.repository["editor"].name
  secret_name = "GPG_PRIVATE_KEY"
  value       = gpg_key_pair.packages.private_key
}

resource "github_actions_secret" "packages_gpg_passphrase" {
  repository  = module.repository["editor"].name
  secret_name = "GPG_PASSPHRASE"
  value       = random_password.packages_gpg_passphrase.result
}
