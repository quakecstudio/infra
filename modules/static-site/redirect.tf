# Optional redirect from other hostnames (e.g. the apex) to the primary domain.
# S3 website hosting answers every request with a 301 to the same path on the
# primary domain; CloudFront adds HTTPS in front of it, which S3 website
# endpoints don't support.

locals {
  redirect_enabled   = length(var.redirect_domain_names) > 0
  redirect_origin_id = "s3-website-redirect"

  redirect_alias_records = local.redirect_enabled ? {
    for pair in setproduct(var.redirect_domain_names, ["A", "AAAA"]) : "${pair[0]}-${pair[1]}" => {
      name = pair[0]
      type = pair[1]
    }
  } : {}
}

# Holds no objects. Redirect-all website hosting doesn't read the bucket, so it
# stays fully private.
resource "aws_s3_bucket" "redirect" {
  count = local.redirect_enabled ? 1 : 0

  bucket           = "${var.name}-redirect-${local.bucket_suffix}"
  bucket_namespace = "account-regional"
  force_destroy    = true
  tags             = var.tags

  lifecycle {
    precondition {
      condition     = local.custom_domain
      error_message = "redirect_domain_names requires domain_names."
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "redirect" {
  count  = local.redirect_enabled ? 1 : 0
  bucket = aws_s3_bucket.redirect[0].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "redirect" {
  count  = local.redirect_enabled ? 1 : 0
  bucket = aws_s3_bucket.redirect[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_website_configuration" "redirect" {
  count  = local.redirect_enabled ? 1 : 0
  bucket = aws_s3_bucket.redirect[0].id

  redirect_all_requests_to {
    host_name = var.domain_names[0]
    protocol  = "https"
  }
}

# Forwards query strings, so the redirect keeps them (e.g. ?utm_source=...),
# but no headers: S3 website hosting finds the bucket by the Host header, so
# forwarding the viewer's Host makes S3 answer NoSuchBucket.
resource "aws_cloudfront_cache_policy" "redirect" {
  count = local.redirect_enabled ? 1 : 0

  name        = "${var.name}-redirect"
  comment     = "Query strings only, for the S3 redirect origin"
  min_ttl     = 0
  default_ttl = 86400
  max_ttl     = 31536000

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = false
    enable_accept_encoding_gzip   = false

    cookies_config {
      cookie_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "all"
    }
  }
}

resource "aws_cloudfront_distribution" "redirect" {
  count = local.redirect_enabled ? 1 : 0

  enabled         = true
  comment         = "${var.name} redirect to ${var.domain_names[0]}"
  is_ipv6_enabled = true
  http_version    = "http2and3"
  price_class     = var.price_class
  aliases         = var.redirect_domain_names
  tags            = var.tags

  # Website endpoints only speak HTTP.
  origin {
    origin_id   = local.redirect_origin_id
    domain_name = aws_s3_bucket_website_configuration.redirect[0].website_endpoint

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = local.redirect_origin_id
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    cache_policy_id        = aws_cloudfront_cache_policy.redirect[0].id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.site[0].certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

resource "aws_route53_record" "redirect" {
  for_each = local.redirect_alias_records

  zone_id = var.route53_zone_id
  name    = each.value.name
  type    = each.value.type

  alias {
    name                   = aws_cloudfront_distribution.redirect[0].domain_name
    zone_id                = aws_cloudfront_distribution.redirect[0].hosted_zone_id
    evaluate_target_health = false
  }
}
