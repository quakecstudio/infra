locals {
  repositories = {
    site = {
      description     = "Website for QuakeC Studio, a modern IDE for QuakeC"
      topics          = ["quake", "quakec", "quake-modding", "website", "static-site", "cloudfront"]
      has_wiki        = false
      has_projects    = false
      has_discussions = false
    }
    infra = {
      description     = "Terraform for QuakeC Studio's AWS and GitHub infrastructure"
      topics          = ["quake", "quakec", "terraform", "aws", "cloudfront", "github-actions", "infrastructure-as-code"]
      has_wiki        = false
      has_projects    = false
      has_discussions = false
      # Pull requests instead of a merge queue; admins can bypass.
      merge_queue          = false
      require_pull_request = true
      bypass_actors = [
        { actor_type = "OrganizationAdmin", bypass_mode = "always" },
        # Repository role 5 is the built-in admin role.
        { actor_type = "RepositoryRole", actor_id = 5, bypass_mode = "always" },
      ]
    }
    editor = {
      description     = "QuakeC Studio: a modern IDE for QuakeC, the scripting language of id Software's Quake"
      topics          = ["quake", "quakec", "quake-modding", "id-tech", "gamedev", "editor", "ide", "code-editor"]
      has_wiki        = true
      has_projects    = true
      has_discussions = true
      # Pull requests instead of a merge queue; admins can bypass.
      merge_queue          = false
      require_pull_request = true
      bypass_actors = [
        { actor_type = "OrganizationAdmin", bypass_mode = "always" },
        # Repository role 5 is the built-in admin role.
        { actor_type = "RepositoryRole", actor_id = 5, bypass_mode = "always" },
      ]
      required_status_checks = [
        "Build (linux-aarch64)",
        "Build (linux-x86_64)",
        "Build (macos-universal)",
        "Build (windows-aarch64)",
        "Build (windows-x86_64)",
        "cargo xtask ci",
        "cargo-deny",
        "Clippy",
        "Dependency Review",
        "Format",
        "Pinned Actions",
        "Test Assets (linux)",
        "Test Assets (macos)",
        "Test Assets (windows)",
        "Unit Tests (linux)",
        "Unit Tests (macos)",
        "Unit Tests (windows)",
        "zizmor",
      ]
    }
    ".github" = {
      description     = "QuakeC Studio organization profile, default community health files and brand assets"
      topics          = ["quake", "quakec", "quake-modding", "community", "github-profile"]
      has_wiki        = false
      has_projects    = false
      has_discussions = false
    }
    "tree-sitter-quakec" = {
      description     = "tree-sitter QuakeC grammar"
      topics          = ["quake", "quakec", "quake-modding"]
      has_wiki        = false
      has_projects    = false
      has_discussions = false
      required_status_checks = [
        "tree-sitter test",
      ]
    }
    kb = {
      description     = "Knowledge base of how QuakeC Studio was built, mined from agent sessions across its repositories"
      topics          = ["quake", "quakec", "knowledge-base"]
      visibility      = "private"
      has_wiki        = false
      has_projects    = false
      has_discussions = false
      # Rulesets and auto-merge need a paid plan on private repositories.
      protect_default_branch = false
      allow_auto_merge       = false
    }
  }

  # Flatten repository => { name => parameter } for the SSM lookups.
  secret_parameters = merge([
    for repo, secrets in var.repository_secrets : {
      for name, parameter in secrets : "${repo}/${name}" => {
        repo      = repo
        name      = name
        parameter = parameter
      }
    }
  ]...)
}

# Secret values live in SSM so they never appear in tfvars or the repo.
data "aws_ssm_parameter" "secret" {
  for_each = local.secret_parameters

  name            = each.value.parameter
  with_decryption = true
}

module "repository" {
  source   = "../../modules/github-repository"
  for_each = local.repositories

  name                   = each.key
  description            = each.value.description
  homepage_url           = "https://www.quakecstudio.com"
  topics                 = each.value.topics
  visibility             = lookup(each.value, "visibility", "public")
  has_wiki               = each.value.has_wiki
  has_projects           = each.value.has_projects
  has_discussions        = each.value.has_discussions
  merge_queue            = lookup(each.value, "merge_queue", true)
  require_pull_request   = lookup(each.value, "require_pull_request", false)
  bypass_actors          = lookup(each.value, "bypass_actors", [])
  protect_default_branch = lookup(each.value, "protect_default_branch", true)
  allow_auto_merge       = lookup(each.value, "allow_auto_merge", true)

  required_status_checks = lookup(each.value, "required_status_checks", [])

  secrets = {
    for key, s in local.secret_parameters : s.name => data.aws_ssm_parameter.secret[key].value
    if s.repo == each.key
  }
}

locals {
  azure = data.terraform_remote_state.azure.outputs

  # Apple values originate outside Terraform; create each SSM parameter first.
  apple_signing_parameters = {
    APPLE_CERTIFICATE_P12_BASE64 = "/quakecstudio/github/editor/release/apple-certificate-p12-base64"
    APPLE_CERTIFICATE_PASSWORD   = "/quakecstudio/github/editor/release/apple-certificate-password"
    APPLE_CERTIFICATE_NAME       = "/quakecstudio/github/editor/release/apple-certificate-name"
    MACOS_KEYCHAIN_PASSWORD      = "/quakecstudio/github/editor/release/macos-keychain-password"
    APPLE_ID                     = "/quakecstudio/github/editor/release/apple-id"
    APPLE_ID_PASSWORD            = "/quakecstudio/github/editor/release/apple-id-password"
    APPLE_TEAM_ID                = "/quakecstudio/github/editor/release/apple-team-id"
  }
}

data "aws_ssm_parameter" "apple_signing" {
  for_each = local.apple_signing_parameters

  name            = each.value
  with_decryption = true
}

# Release signing secrets, named as in quack's and vouch's release workflows.
# The Azure ones are consumed by skeeto/aas-sign through the federated
# credential, whose custom OIDC subject omits the environment, so running the
# release job in this environment still matches it.
module "editor_release" {
  source = "../../modules/github-environment"

  repository  = module.repository["editor"].name
  environment = "release"

  secrets = merge(
    { for name, _ in local.apple_signing_parameters : name => data.aws_ssm_parameter.apple_signing[name].value },
    {
      AZURE_CLIENT_ID          = local.azure.signing_client_id
      AZURE_TENANT_ID          = local.azure.signing_tenant_id
      CERTIFICATE_PROFILE      = local.azure.signing_profile
      TRUSTED_SIGNING_ACCOUNT  = local.azure.signing_account
      TRUSTED_SIGNING_ENDPOINT = local.azure.signing_endpoint
    },
  )
}
