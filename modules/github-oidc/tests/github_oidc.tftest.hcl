# Plan-only tests against a mocked AWS provider: no credentials needed.
#   terraform init && terraform test

mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{}"
    }
  }
}

variables {
  subject_prefix = "repo:quakecstudio@343029298/site@1420765651"
  roles = {
    dev  = "quakecstudio-dev-site-deploy"
    prod = "quakecstudio-prod-site-deploy"
  }
}

run "roles_per_environment" {
  command = plan

  assert {
    condition     = length(aws_iam_role.deploy) == 2
    error_message = "One role per environment expected."
  }

  assert {
    condition     = aws_iam_role.deploy["prod"].name == "quakecstudio-prod-site-deploy"
    error_message = "Role names should come from the roles map."
  }

  assert {
    condition = contains(
      flatten([for c in data.aws_iam_policy_document.trust["dev"].statement[0].condition : c.values]),
      "repo:quakecstudio@343029298/site@1420765651:environment:dev"
    )
    error_message = "dev role must only trust the dev Environment."
  }
}
