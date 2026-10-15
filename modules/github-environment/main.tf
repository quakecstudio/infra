resource "github_repository_environment" "this" {
  repository  = var.repository
  environment = var.environment

  # A sole maintainer has to be able to approve their own deploys.
  prevent_self_review = false

  dynamic "reviewers" {
    for_each = length(var.reviewer_user_ids) > 0 ? [var.reviewer_user_ids] : []

    content {
      users = reviewers.value
    }
  }

  dynamic "deployment_branch_policy" {
    for_each = length(var.deployment_branches) > 0 ? [true] : []

    content {
      protected_branches     = false
      custom_branch_policies = true
    }
  }
}

resource "github_repository_environment_deployment_policy" "this" {
  for_each = toset(var.deployment_branches)

  repository     = var.repository
  environment    = github_repository_environment.this.environment
  branch_pattern = each.value
}

resource "github_actions_environment_variable" "this" {
  for_each = var.variables

  repository    = var.repository
  environment   = github_repository_environment.this.environment
  variable_name = each.key
  value         = each.value
}

# Secret names aren't sensitive, only their values.
resource "github_actions_environment_secret" "this" {
  for_each = nonsensitive(toset(keys(var.secrets)))

  repository  = var.repository
  environment = github_repository_environment.this.environment
  secret_name = each.key
  value       = var.secrets[each.key]
}
