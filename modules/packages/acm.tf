# CloudFront only accepts certificates from us-east-1, hence the aliased provider.

resource "aws_acm_certificate" "packages" {
  provider = aws.us_east_1

  domain_name       = var.domain_name
  validation_method = "DNS"
  tags              = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  zone_id         = var.route53_zone_id
  name            = local.cert_validation_options[var.domain_name].resource_record_name
  type            = local.cert_validation_options[var.domain_name].resource_record_type
  records         = [local.cert_validation_options[var.domain_name].resource_record_value]
  ttl             = 300
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "packages" {
  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.packages.arn
  validation_record_fqdns = [aws_route53_record.cert_validation.fqdn]
}
