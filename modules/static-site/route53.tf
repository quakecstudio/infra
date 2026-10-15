# Alias records pointing each custom hostname at the distribution.

locals {
  alias_records = local.custom_domain ? {
    for pair in setproduct(var.domain_names, ["A", "AAAA"]) : "${pair[0]}-${pair[1]}" => {
      name = pair[0]
      type = pair[1]
    }
  } : {}
}

resource "aws_route53_record" "site" {
  for_each = local.alias_records

  zone_id = var.route53_zone_id
  name    = each.value.name
  type    = each.value.type

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}
