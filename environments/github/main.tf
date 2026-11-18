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
        "Test Assets (linux)",
        "Test Assets (macos)",
        "Test Assets (windows)",
        "Unit Tests (linux)",
        "Unit Tests (macos)",
        "Unit Tests (windows)",
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
    # The editor's release workflow pushes straight to main in both of these
    # with a fine-grained token, so neither uses a merge queue or pull requests.
    packages = {
      description     = "QuakeC Studio APT and YUM/DNF package repository"
      topics          = ["quake", "quakec", "apt", "debian", "rpm"]
      has_wiki        = false
      has_projects    = false
      has_discussions = false
      merge_queue     = false
    }
    "homebrew-tap" = {
      description     = "Homebrew tap for QuakeC Studio"
      topics          = ["quake", "quakec", "homebrew", "homebrew-tap"]
      has_wiki        = false
      has_projects    = false
      has_discussions = false
      merge_queue     = false
    }
    # komac, in the editor's release workflow, pushes manifest branches here
    # and opens pull requests against microsoft/winget-pkgs from them. Its
    # sync-fork step updates master, so the branch is left unprotected.
    "winget-pkgs" = {
      description            = "Fork of microsoft/winget-pkgs that QuakeC Studio's winget manifests are submitted from"
      topics                 = []
      fork_of                = { owner = "microsoft", repo = "winget-pkgs" }
      default_branch         = "master"
      has_issues             = false
      has_wiki               = false
      has_projects           = false
      has_discussions        = false
      protect_default_branch = false
    }
  }

  # Repository-level Actions secrets that originate outside Terraform:
  # repository => { SECRET_NAME = "<SSM SecureString parameter name>" }. Create
  # the parameter first, or every plan of this root fails:
  #   aws ssm put-parameter --profile quakecstudio-admin --type SecureString \
  #     --name /quakecstudio/github/editor/winget-token --value '...'
  repository_secrets = {
    editor = {
      # Classic personal access token with the public_repo scope. komac opens
      # pull requests on microsoft/winget-pkgs with it, which needs a user
      # identity that has signed Microsoft's CLA.
      WINGET_TOKEN = "/quakecstudio/github/editor/winget-token"
    }
  }

  # Flatten repository => { name => parameter } for the SSM lookups.
  secret_parameters = merge([
    for repo, secrets in local.repository_secrets : {
      for name, parameter in secrets : "${repo}/${name}" => {
        repo      = repo
        name      = name
        parameter = parameter
      }
    }
  ]...)
}

# Secret values live in SSM so they never appear in the repo.
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
  fork_of                = lookup(each.value, "fork_of", null)
  default_branch         = lookup(each.value, "default_branch", "main")
  has_issues             = lookup(each.value, "has_issues", true)
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
