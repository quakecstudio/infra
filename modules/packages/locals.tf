locals {
  # Keyed by the configured hostname (known at plan time) rather than by the
  # certificate's validation options (known only after the cert exists).
  cert_validation_options = {
    for dvo in aws_acm_certificate.packages.domain_validation_options : dvo.domain_name => dvo
  }

  oidc_host = "token.actions.githubusercontent.com"

  # Buckets live in the account-regional namespace, which only this account
  # can create names in: <prefix>-<account-id>-<region>-an.
  bucket_suffix = "${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
}
