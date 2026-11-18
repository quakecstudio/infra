resource "aws_route53_record" "packages" {
  for_each = toset(["A", "AAAA"])

  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = each.key

  alias {
    name                   = aws_cloudfront_distribution.packages.domain_name
    zone_id                = aws_cloudfront_distribution.packages.hosted_zone_id
    evaluate_target_health = false
  }
}
