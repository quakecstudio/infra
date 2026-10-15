# github-environment

A GitHub Environment in one repository, with optional deployment branch rules
and required reviewers, plus its Actions variables and secrets.

```hcl
module "github_environment" {
  source = "../../modules/github-environment"

  repository          = "site"
  environment         = "production"
  deployment_branches = ["main"]   # optional; empty = any branch
  reviewer_user_ids   = []         # optional; GitHub user IDs who must approve

  variables = { SITE_BUCKET = "..." }
  secrets   = { API_TOKEN = data.aws_ssm_parameter.api_token.value }
}
```

Secret values are stored (encrypted) in Terraform state.
