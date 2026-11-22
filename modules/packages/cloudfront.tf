resource "aws_cloudfront_origin_access_control" "packages" {
  name                              = var.name
  description                       = "Origin access for ${var.name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Requests reach S3 with their path unchanged. APT and DNF fetch extensionless
# files such as dists/stable/InRelease, so nothing here may rewrite
# directory-style URLs to index.html the way the static-site module does.
resource "aws_cloudfront_distribution" "packages" {
  enabled             = true
  comment             = var.name
  is_ipv6_enabled     = true
  http_version        = "http2and3"
  price_class         = var.price_class
  default_root_object = "index.html"
  aliases             = [var.domain_name]
  tags                = var.tags

  origin {
    origin_id                = "s3-${aws_s3_bucket.packages.id}"
    domain_name              = aws_s3_bucket.packages.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.packages.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-${aws_s3_bucket.packages.id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    cache_policy_id        = data.aws_cloudfront_cache_policy.caching_optimized.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.packages.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}
