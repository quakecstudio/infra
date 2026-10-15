# QuakeC Studio — infra

Terraform for the QuakeC Studio website: a private S3 bucket served through
CloudFront. The page itself lives in
[`quakecstudio/site`](https://github.com/quakecstudio/site).

```
modules/
├── static-site/          # S3 bucket + CloudFront (OAC), security headers,
│                         # optional ACM cert + Route 53 records
└── github-deploy-role/   # IAM role GitHub Actions assumes via OIDC to deploy
environments/
├── staging/
└── production/
```

## Requirements

- Terraform >= 1.10 (S3 backend uses native lockfile locking)
- AWS provider ~> 6.0
- An S3 bucket for Terraform state (create it once, by hand or elsewhere;
  enable versioning on it)

## Usage

```sh
cd environments/production
cp backend.hcl.example backend.hcl            # set the state bucket
cp terraform.tfvars.example terraform.tfvars  # optional settings
terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

Without `domain_names` the site is available at the `*.cloudfront.net` URL in
the `site_url` output. To use a custom domain, set `domain_names` and the
`route53_zone_id` of the hosted zone serving it; the module requests and
validates an ACM certificate in us-east-1 and creates `A`/`AAAA` aliases.

### GitHub OIDC provider

The GitHub Actions OIDC provider is one per AWS account. If staging and
production share an account, apply one first (it creates the provider), then
in the other set:

```hcl
create_github_oidc_provider = false
github_oidc_provider_arn    = "<github_oidc_provider_arn output from the first>"
```

## Connecting the site repo

After `apply`, create a GitHub environment with the same name (`staging` or
`production`) in `quakecstudio/site` and add these variables:

| GitHub variable              | Terraform output   |
| ---------------------------- | ------------------ |
| `AWS_REGION`                 | `aws_region`       |
| `AWS_DEPLOY_ROLE_ARN`        | `deploy_role_arn`  |
| `SITE_BUCKET`                | `bucket_name`      |
| `CLOUDFRONT_DISTRIBUTION_ID` | `distribution_id`  |
| `SITE_URL`                   | `site_url`         |

The deploy role only trusts jobs from `quakecstudio/site` running in that
GitHub environment.

## CI

`.github/workflows/terraform.yml` runs `terraform fmt -check` and
`terraform validate` for each environment, plus `terraform test` for the
`static-site` module against a mocked AWS provider, on pull requests and
pushes to `main`. It does not plan or apply against AWS.
