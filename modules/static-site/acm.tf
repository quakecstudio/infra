# TLS certificate for custom domains. CloudFront only accepts certificates
# from us-east-1, hence the aliased provider.

locals {
  custom_domain = length(var.domain_names) > 0
}

resource "aws_acm_certificate" "site" {
  count    = local.custom_domain ? 1 : 0
  provider = aws.us_east_1

  domain_name               = var.domain_names[0]
  subject_alternative_names = slice(var.domain_names, 1, length(var.domain_names))
  validation_method         = "DNS"
  tags                      = var.tags

  lifecycle {
    create_before_destroy = true

    precondition {
      condition     = var.route53_zone_id != null
      error_message = "route53_zone_id is required when domain_names is set."
    }
  }
}

# Keyed by the configured hostnames (known at plan time) rather than by the
# certificate's validation options (known only after the cert exists).
locals {
  cert_validation_options = local.custom_domain ? {
    for dvo in aws_acm_certificate.site[0].domain_validation_options : dvo.domain_name => dvo
  } : {}
}

resource "aws_route53_record" "cert_validation" {
  for_each = toset(local.custom_domain ? var.domain_names : [])

  zone_id         = var.route53_zone_id
  name            = local.cert_validation_options[each.key].resource_record_name
  type            = local.cert_validation_options[each.key].resource_record_type
  records         = [local.cert_validation_options[each.key].resource_record_value]
  ttl             = 300
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "site" {
  count    = local.custom_domain ? 1 : 0
  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.site[0].arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}
