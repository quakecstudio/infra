# Plan-only tests against a mocked AWS provider: no credentials needed.
#   terraform init && terraform test

mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{}"
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
    condition     = aws_s3_bucket_public_access_block.site.restrict_public_buckets
    error_message = "Bucket must block public access."
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
