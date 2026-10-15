# static-site

Private S3 bucket + CloudFront distribution for a static website.

- Bucket is private (public access blocked, ACLs disabled, SSE-S3,
  versioning with 30-day non-current expiry, TLS-only policy).
- CloudFront reads the bucket through Origin Access Control (SigV4).
- HTTPS only, HTTP/2 + HTTP/3, IPv6, compression, `Managed-CachingOptimized`.
- Security headers (CSP, HSTS, X-Frame-Options, nosniff, Referrer-Policy,
  Permissions-Policy) via a response headers policy.
- A CloudFront Function rewrites `/path/` and `/path` to `/path/index.html`.
- 403/404 from S3 are served as `/404.html` with status 404.
- Optional API: a Lambda function URL served uncached at `/api/*`, signed with
  Lambda origin access control (`api_origin`). The distribution-wide 403/404
  error pages also apply to `/api/*`, so APIs should avoid those codes for
  JSON errors.
- Optional custom domains: ACM certificate (us-east-1, DNS-validated) and
  Route 53 `A`/`AAAA` alias records.

## Usage

```hcl
module "site" {
  source = "../../modules/static-site"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  name            = "quakecstudio-production"
  domain_names    = ["quakec.studio", "www.quakec.studio"] # optional
  route53_zone_id = "Z0123456789ABCDEFGHIJ"                 # required with domain_names
}
```

The caller must pass an `aws.us_east_1` provider alias; it is only used for
the ACM certificate.

## Inputs

| Name                      | Default            | Description                                        |
| ------------------------- | ------------------ | -------------------------------------------------- |
| `name`                    | —                  | Name prefix for all resources.                     |
| `domain_names`            | `[]`               | Custom hostnames; first is primary.                |
| `route53_zone_id`         | `null`             | Hosted zone for `domain_names`.                    |
| `price_class`             | `PriceClass_100`   | CloudFront price class.                            |
| `content_security_policy` | strict self-only   | CSP header value.                                  |
| `force_destroy`           | `false`            | Allow destroying a non-empty bucket.               |
| `api_origin`              | `null`             | `{ domain_name, function_name }` for `/api/*`.     |
| `deploy_role_name`        | `null`             | IAM role to grant upload + invalidation access.    |
| `tags`                    | `{}`               | Tags for all resources.                            |

## Outputs

`bucket_name`, `bucket_arn`, `distribution_id`, `distribution_arn`,
`distribution_domain_name`, `site_url`.
