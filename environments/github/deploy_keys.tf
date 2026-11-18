# SSH deploy keys the editor's release workflow pushes with. Terraform makes
# each key pair, registers the public half with write access on the target
# repository and stores the private half as a secret on quakecstudio/editor, so
# no personal access token is involved. Pushes made with a deploy key, unlike
# GITHUB_TOKEN pushes, start the target repository's workflows.
#
# The organization must allow deploy keys, which the GitHub provider can't set:
#   gh api -X PATCH orgs/quakecstudio -F deploy_keys_enabled_for_repositories=true

locals {
  # Secret on quakecstudio/editor => repository its release workflow pushes to.
  release_deploy_keys = {
    PACKAGES_DEPLOY_KEY     = "packages"
    HOMEBREW_TAP_DEPLOY_KEY = "homebrew-tap"
  }
}

resource "tls_private_key" "release" {
  for_each = local.release_deploy_keys

  algorithm = "ED25519"
}

resource "github_repository_deploy_key" "release" {
  for_each = local.release_deploy_keys

  repository = module.repository[each.value].name
  title      = "quakecstudio/editor release workflow"
  key        = tls_private_key.release[each.key].public_key_openssh
  read_only  = false
}

resource "github_actions_secret" "release_deploy_key" {
  for_each = local.release_deploy_keys

  repository  = module.repository["editor"].name
  secret_name = each.key
  value       = tls_private_key.release[each.key].private_key_openssh
}
