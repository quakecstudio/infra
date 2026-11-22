locals {
  custom_domain = length(var.domain_names) > 0

  # One certificate covers the site and its redirect hostnames.
  certificate_names = concat(var.domain_names, var.redirect_domain_names)

  # Keyed by the configured hostnames (known at plan time) rather than by the
  # certificate's validation options (known only after the cert exists).
  cert_validation_options = local.custom_domain ? {
    for dvo in aws_acm_certificate.site[0].domain_validation_options : dvo.domain_name => dvo
  } : {}

  api_enabled   = var.api_origin != null
  api_origin_id = "lambda-api"

  redirect_enabled   = length(var.redirect_domain_names) > 0
  redirect_origin_id = "s3-website-redirect"

  redirect_alias_records = local.redirect_enabled ? {
    for pair in setproduct(var.redirect_domain_names, ["A", "AAAA"]) : "${pair[0]}-${pair[1]}" => {
      name = pair[0]
      type = pair[1]
    }
  } : {}

  alias_records = local.custom_domain ? {
    for pair in setproduct(var.domain_names, ["A", "AAAA"]) : "${pair[0]}-${pair[1]}" => {
      name = pair[0]
      type = pair[1]
    }
  } : {}

  # Buckets live in the account-regional namespace, which only this account
  # can create names in: <prefix>-<account-id>-<region>-an.
  bucket_suffix = "${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
}
