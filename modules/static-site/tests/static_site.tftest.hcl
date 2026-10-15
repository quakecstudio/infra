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
  name = "quakecstudio-test"
}

run "default_domain" {
  command = plan

  assert {
    condition     = length(aws_acm_certificate.site) == 0 && length(aws_route53_record.site) == 0
    error_message = "No certificate or DNS records expected without domain_names."
  }

  assert {
    condition     = aws_cloudfront_distribution.site.viewer_certificate[0].cloudfront_default_certificate
    error_message = "Default CloudFront certificate expected without domain_names."
  }

  assert {
    condition     = length(aws_cloudfront_distribution.site.ordered_cache_behavior) == 0 && length(aws_lambda_permission.api_url) == 0
    error_message = "No API origin expected without api_origin."
  }

  assert {
    condition     = length(aws_iam_role_policy.deploy) == 0
    error_message = "No deploy policy expected without deploy_role_name."
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.site.restrict_public_buckets
    error_message = "Bucket must block public access."
  }

  assert {
    condition     = aws_s3_bucket.site.bucket == "quakecstudio-test-123456789012-us-east-1-an" && aws_s3_bucket.site.bucket_namespace == "account-regional"
    error_message = "Bucket should be named <name>-<account-id>-<region>-an in the account-regional namespace."
  }
}

run "custom_domain" {
  command = plan

  variables {
    domain_names    = ["quakec.example", "www.quakec.example"]
    route53_zone_id = "Z0000000000000000000"
  }

  assert {
    condition     = length(aws_acm_certificate.site) == 1
    error_message = "One certificate expected."
  }

  assert {
    condition     = length(aws_route53_record.site) == 4
    error_message = "A and AAAA records expected for each domain."
  }

  assert {
    condition     = output.site_url == "https://quakec.example"
    error_message = "site_url should use the primary custom domain."
  }
}

run "domain_requires_zone" {
  command = plan

  variables {
    domain_names = ["quakec.example"]
  }

  expect_failures = [aws_acm_certificate.site]
}

run "api_origin" {
  command = plan

  variables {
    api_origin = {
      domain_name   = "abc123.lambda-url.us-east-1.on.aws"
      function_name = "quakecstudio-test-visit-counter"
    }
  }

  assert {
    condition     = length(aws_cloudfront_origin_access_control.api) == 1
    error_message = "Lambda origin access control expected."
  }

  assert {
    condition     = aws_cloudfront_distribution.site.ordered_cache_behavior[0].path_pattern == "/api/*"
    error_message = "/api/* behavior expected."
  }

  assert {
    condition     = length(aws_lambda_permission.api_url) == 1 && length(aws_lambda_permission.api_invoke) == 1
    error_message = "CloudFront needs both invoke permissions."
  }
}

run "deploy_role" {
  command = plan

  variables {
    deploy_role_name = "quakecstudio-test-site-deploy"
  }

  assert {
    condition     = aws_iam_role_policy.deploy[0].role == "quakecstudio-test-site-deploy"
    error_message = "Deploy policy should attach to the given role."
  }
}

run "redirect" {
  command = plan

  variables {
    domain_names          = ["www.quakec.example"]
    redirect_domain_names = ["quakec.example"]
    route53_zone_id       = "Z0000000000000000000"
  }

  assert {
    condition     = aws_s3_bucket_website_configuration.redirect[0].redirect_all_requests_to[0].host_name == "www.quakec.example"
    error_message = "Redirect should target the primary domain."
  }

  assert {
    condition     = aws_s3_bucket_website_configuration.redirect[0].redirect_all_requests_to[0].protocol == "https"
    error_message = "Redirect should use HTTPS."
  }

  assert {
    condition     = aws_s3_bucket.redirect[0].bucket == "quakecstudio-test-redirect-123456789012-us-east-1-an"
    error_message = "Redirect bucket should be in the account-regional namespace."
  }

  assert {
    condition     = aws_cloudfront_cache_policy.redirect[0].parameters_in_cache_key_and_forwarded_to_origin[0].headers_config[0].header_behavior == "none"
    error_message = "The redirect origin must not receive the viewer's Host header, or S3 answers NoSuchBucket."
  }

  assert {
    condition     = aws_cloudfront_cache_policy.redirect[0].parameters_in_cache_key_and_forwarded_to_origin[0].query_strings_config[0].query_string_behavior == "all"
    error_message = "The redirect must keep query strings."
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.redirect[0].restrict_public_buckets
    error_message = "Redirect bucket must block public access."
  }

  assert {
    condition     = toset(aws_acm_certificate.site[0].subject_alternative_names) == toset(["quakec.example"])
    error_message = "The certificate should also cover the redirect hostnames."
  }

  assert {
    condition     = length(aws_route53_record.redirect) == 2 && length(aws_route53_record.cert_validation) == 2
    error_message = "A/AAAA aliases and certificate validation expected for the redirect hostname."
  }
}

run "redirect_requires_domain" {
  command = plan

  variables {
    redirect_domain_names = ["quakec.example"]
    route53_zone_id       = "Z0000000000000000000"
  }

  expect_failures = [aws_s3_bucket.redirect]
}
