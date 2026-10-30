# Plan-only tests against a mocked GitHub provider: no token needed.
#   terraform init && terraform test

mock_provider "github" {}

variables {
  name        = "example"
  description = "Example repository"
}

run "defaults" {
  command = plan

  assert {
    condition     = github_branch_default.this.branch == "main"
    error_message = "Default branch should be main."
  }

  assert {
    condition     = length(github_repository_ruleset.default_branch) == 1
    error_message = "Default branch should be protected."
  }

  assert {
    condition     = length(github_repository_ruleset.default_branch[0].rules[0].pull_request) == 0
    error_message = "Pull requests should not be required by default."
  }

  assert {
    condition     = length(github_repository_ruleset.default_branch[0].rules[0].merge_queue) == 0
    error_message = "Merge queue should be off by default."
  }

  assert {
    condition     = length(github_repository_ruleset.default_branch[0].bypass_actors) == 0
    error_message = "No bypass actors by default."
  }

  assert {
    condition     = github_repository.this.archive_on_destroy
    error_message = "Repositories must be archived, not deleted."
  }
}

run "pull_requests_and_secrets" {
  command = plan

  variables {
    require_pull_request   = true
    required_status_checks = ["validate"]
    secrets                = { TOKEN = "s3cr3t" }
    variables              = { REGION = "us-east-1" }
  }

  assert {
    condition     = length(github_repository_ruleset.default_branch[0].rules[0].pull_request) == 1
    error_message = "Pull request rule expected."
  }

  assert {
    condition     = contains(keys(github_actions_secret.this), "TOKEN")
    error_message = "Secret TOKEN expected."
  }

  assert {
    condition     = github_actions_variable.this["REGION"].value == "us-east-1"
    error_message = "Variable REGION expected."
  }
}

run "merge_queue" {
  command = plan

  variables {
    merge_queue = true
  }

  assert {
    condition     = github_repository_ruleset.default_branch[0].rules[0].merge_queue[0].merge_method == "SQUASH"
    error_message = "Merge queue must squash, the only merge method the repository allows."
  }
}

run "linear_history" {
  command = plan

  assert {
    condition     = github_repository_ruleset.default_branch[0].rules[0].required_linear_history
    error_message = "Linear history should be required by default."
  }
}

run "auto_merge" {
  command = plan

  assert {
    condition     = github_repository.this.allow_auto_merge
    error_message = "Auto-merge must be on so gh pr merge can add PRs to the merge queue."
  }
}

run "private_without_auto_merge" {
  command = plan

  variables {
    visibility             = "private"
    protect_default_branch = false
    allow_auto_merge       = false
  }

  assert {
    condition     = !github_repository.this.allow_auto_merge
    error_message = "Auto-merge must be configurable off for private repositories on GitHub Free."
  }

  assert {
    condition     = length(github_repository_ruleset.default_branch) == 0
    error_message = "No ruleset expected when protect_default_branch is false."
  }
}

run "bypass_actors" {
  command = plan

  variables {
    require_pull_request = true
    bypass_actors = [
      { actor_type = "OrganizationAdmin", bypass_mode = "always" },
      { actor_type = "RepositoryRole", actor_id = 5, bypass_mode = "always" },
    ]
  }

  assert {
    condition     = length(github_repository_ruleset.default_branch[0].bypass_actors) == 2
    error_message = "Both bypass actors expected."
  }

  assert {
    condition     = github_repository_ruleset.default_branch[0].bypass_actors[0].actor_id == null
    error_message = "OrganizationAdmin has no actor ID."
  }

  assert {
    condition     = github_repository_ruleset.default_branch[0].rules[0].pull_request[0].allowed_merge_methods == tolist(["squash"])
    error_message = "Pull requests must squash, the only merge method the repository allows."
  }
}
