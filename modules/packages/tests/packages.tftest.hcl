# Plan-only tests against a mocked AWS provider: no credentials needed.
#   terraform init && terraform test

mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{}"
    }
  }

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }

  mock_data "aws_region" {
    defaults = {
      region = "us-east-1"
    }
  }
}

mock_provider "aws" {
  alias = "us_east_1"
}

variables {
  name                     = "quakecstudio-packages"
  domain_name              = "packages.example.com"
  route53_zone_id          = "Z0123456789ABCDEFGHIJ"
  github_oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
  github_subject_prefix    = "repo:quakecstudio@1/packages@2"
}

run "defaults" {
  command = plan

  assert {
    condition     = aws_s3_bucket.packages.bucket == "quakecstudio-packages-123456789012-us-east-1-an"
    error_message = "Bucket must use the account-regional name."
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.packages.restrict_public_buckets
    error_message = "Bucket must block public access."
  }

  assert {
    condition     = aws_cloudfront_distribution.packages.aliases == toset(["packages.example.com"])
    error_message = "Distribution must serve the configured hostname."
  }

  assert {
    condition     = length(aws_cloudfront_distribution.packages.default_cache_behavior[0].function_association) == 0
    error_message = "Request paths must reach S3 unchanged: APT and DNF fetch extensionless files."
  }

  assert {
    condition     = toset(keys(aws_route53_record.packages)) == toset(["A", "AAAA"])
    error_message = "A and AAAA alias records expected."
  }

  assert {
    condition = contains(
      flatten([for c in data.aws_iam_policy_document.publish_trust.statement[0].condition : c.values]),
      "repo:quakecstudio@1/packages@2:ref:refs/heads/main",
    )
    error_message = "Only the publishing repository's default branch may assume the publish role."
  }

  assert {
    condition = alltrue([
      for c in data.aws_iam_policy_document.publish_trust.statement[0].condition : c.test == "StringEquals"
    ])
    error_message = "Trust conditions must match exactly, with no wildcards."
  }

  assert {
    condition     = aws_iam_role.publish.name == "quakecstudio-packages-publish"
    error_message = "Publish role name must derive from name."
  }
}

run "other_default_branch" {
  command = plan

  variables {
    github_default_branch = "release"
  }

  assert {
    condition = contains(
      flatten([for c in data.aws_iam_policy_document.publish_trust.statement[0].condition : c.values]),
      "repo:quakecstudio@1/packages@2:ref:refs/heads/release",
    )
    error_message = "Trust must follow github_default_branch."
  }
}

run "rejects_long_name" {
  command = plan

  variables {
    name = "quakecstudio-packages-with-a-name-that-is-too-long"
  }

  expect_failures = [var.name]
}

run "rejects_unknown_price_class" {
  command = plan

  variables {
    price_class = "PriceClass_50"
  }

  expect_failures = [var.price_class]
}
