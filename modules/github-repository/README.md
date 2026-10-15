# github-repository

Settings for one GitHub repository: description, topics, features,
squash-only merges, Dependabot alerts off, default branch, a default-branch
ruleset (no deletion, no force push; optionally require pull requests, status
checks, and a squashing merge queue), and repo-level Actions variables and secrets.

The repository is archived, never deleted, if it leaves Terraform, and
`prevent_destroy` guards against accidental destroys. To adopt an existing
repository, import `github_repository.this` and `github_branch_default.this`
by repository name.

Secret values are stored (encrypted) in Terraform state.
