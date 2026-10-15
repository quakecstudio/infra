resource "github_repository" "this" {
  name         = var.name
  description  = var.description
  homepage_url = var.homepage_url
  topics       = var.topics
  visibility   = var.visibility

  has_issues      = var.has_issues
  has_wiki        = var.has_wiki
  has_projects    = var.has_projects
  has_discussions = var.has_discussions

  # Squash merges only; the PR title becomes the commit subject. gh pr merge
  # adds a PR to the merge queue through auto-merge, which can't bypass the
  # required queue.
  allow_squash_merge          = true
  allow_merge_commit          = false
  allow_rebase_merge          = false
  allow_auto_merge            = true
  allow_update_branch         = true
  delete_branch_on_merge      = true
  squash_merge_commit_title   = "PR_TITLE"
  squash_merge_commit_message = "PR_BODY"

  # Never delete a repository from Terraform.
  archive_on_destroy = true

  lifecycle {
    prevent_destroy = true
  }
}

# Dependabot alerts are noise for these repositories. Managed explicitly so they
# stay off instead of following the account default.
resource "github_repository_vulnerability_alerts" "this" {
  repository = github_repository.this.name
  enabled    = false
}

resource "github_branch_default" "this" {
  repository = github_repository.this.name
  branch     = var.default_branch
}

resource "github_repository_ruleset" "default_branch" {
  count = var.protect_default_branch ? 1 : 0

  name        = "default-branch"
  repository  = github_repository.this.name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  rules {
    deletion         = true
    non_fast_forward = true

    dynamic "pull_request" {
      for_each = var.require_pull_request ? [true] : []

      content {
        required_approving_review_count   = 0
        dismiss_stale_reviews_on_push     = true
        required_review_thread_resolution = true
      }
    }

    dynamic "merge_queue" {
      for_each = var.merge_queue ? [true] : []

      # Squash to match the repository's only allowed merge method.
      content {
        merge_method = "SQUASH"
      }
    }

    dynamic "required_status_checks" {
      for_each = length(var.required_status_checks) > 0 ? [true] : []

      content {
        strict_required_status_checks_policy = false

        dynamic "required_check" {
          for_each = var.required_status_checks

          content {
            context = required_check.value
          }
        }
      }
    }
  }
}

resource "github_actions_variable" "this" {
  for_each = var.variables

  repository    = github_repository.this.name
  variable_name = each.key
  value         = each.value
}

# Secret names aren't sensitive, only their values.
resource "github_actions_secret" "this" {
  for_each = nonsensitive(toset(keys(var.secrets)))

  repository  = github_repository.this.name
  secret_name = each.key
  value       = var.secrets[each.key]
}
