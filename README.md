# QuakeC Studio — infra

Terraform for the QuakeC Studio website: a private S3 bucket served through
CloudFront. The page itself lives in
[`quakecstudio/site`](https://github.com/quakecstudio/site).

```
modules/
├── static-site/          # S3 bucket + CloudFront (OAC), security headers,
│                         # optional ACM cert + Route 53 records
├── visit-counter/        # Lambda + DynamoDB visitor counter at /api/visit
├── github-oidc/          # GitHub Actions OIDC provider + per-environment deploy roles
├── github-environment/   # GitHub Environment, deploy branch rules, Actions
│                         # variables and secrets
└── github-repository/    # Repository settings, default branch, branch
                          # ruleset, repo-level Actions variables and secrets
environments/
├── global/               # account-wide: GitHub OIDC provider and deploy roles
├── github/               # settings for every quakecstudio repository
├── dev/                  # site + its "dev" GitHub Environment in quakecstudio/site
└── production/           # site + its "production" GitHub Environment
```

Each environment is its own Terraform root with its own state. Apply
`global` first: `dev` and `production` look up the deploy roles it creates.

## Requirements

- Terraform >= 1.10 (S3 backend uses native lockfile locking)
- AWS provider ~> 6.0
- A GitHub token that can administer the `quakecstudio` repositories, in
  `GITHUB_TOKEN` (e.g. `GITHUB_TOKEN=$(gh auth token)`), for every root
  except `global`
- An S3 bucket for Terraform state (create it once, by hand or elsewhere;
  enable versioning on it)

## Usage

```sh
cd environments/global
cp backend.hcl.example backend.hcl            # set the state bucket
terraform init -backend-config=backend.hcl
terraform apply

cd ../production
cp backend.hcl.example backend.hcl            # set the state bucket
cp terraform.tfvars.example terraform.tfvars  # optional settings
terraform init -backend-config=backend.hcl
GITHUB_TOKEN=$(gh auth token) terraform plan
GITHUB_TOKEN=$(gh auth token) terraform apply
```

Without `domain_names` the site is available at the `*.cloudfront.net` URL in
the `site_url` output. To use a custom domain, set `domain_names` and the
`route53_zone_id` of the hosted zone serving it; the module requests and
validates an ACM certificate in us-east-1 and creates `A`/`AAAA` aliases.

### Deploy roles

`environments/global` creates the account's GitHub Actions OIDC provider and
one IAM role per GitHub Environment: `quakecstudio-dev-site-deploy` and
`quakecstudio-production-site-deploy`. Each role only trusts jobs from
`quakecstudio/site` running in the matching Environment
(`repo:quakecstudio/site:environment:<env>`) and has no permissions of its own.
`dev` and `production` look their role up and attach an inline policy that
allows uploading to their own bucket and invalidating their own distribution,
and nothing else.

To add an environment, add it to `roles` in `environments/global/main.tf`
and apply `global` before the new root.

## Visitor counter

Each environment runs `modules/visit-counter`: a Node.js Lambda function and a
one-item DynamoDB table, served through the site's CloudFront distribution at
`/api/visit` (`GET` reads the total, `POST` adds one). The function URL only
accepts requests signed by CloudFront. Reserved concurrency is 5, so a flood
of requests is throttled instead of running up a bill.

Lambda keeps at least 10 concurrent executions unreserved per account. If the
account's concurrency quota is still the new-account default of 10, the
reservation fails: request an increase under Service Quotas → AWS Lambda →
Concurrent executions before applying.

## GitHub

All GitHub configuration is managed here with the
[`integrations/github`](https://registry.terraform.io/providers/integrations/github/latest)
provider; don't change these settings in the GitHub UI.

### Deploy environments

`dev` and `production` each create the matching GitHub Environment in
`quakecstudio/site` and set the Actions variables its deploy workflow reads,
straight from their own resources:

| Variable                     | Source                     |
| ---------------------------- | -------------------------- |
| `AWS_REGION`                 | `var.aws_region`           |
| `AWS_DEPLOY_ROLE_ARN`        | the deploy role            |
| `SITE_BUCKET`                | the site bucket            |
| `CLOUDFRONT_DISTRIBUTION_ID` | the distribution           |
| `SITE_URL`                   | the site URL               |

The `production` Environment only accepts deploys from `main`, and each
production deploy waits for approval from jplock. The deploy role
only trusts jobs from `quakecstudio/site` running in the matching Environment.

### Repositories

`environments/github` manages `site`, `infra` and `editor`: description and
topics, features (issues on, wiki off, projects on for `editor` only), squash-only
merges with branch deletion after merge, Dependabot alerts, `main` as the
default branch, and a ruleset that blocks deleting or force-pushing it. The
repositories already existed, so `imports.tf` adopts them on the first apply.
Removing one from Terraform archives it rather than deleting it.

```sh
cd environments/github
terraform init -backend-config=backend.hcl
GITHUB_TOKEN=$(gh auth token) terraform plan
```

### Secrets

Secret values live in SSM Parameter Store as `SecureString` parameters, created
outside Terraform so they never appear in tfvars or the repo:

```sh
aws ssm put-parameter --type SecureString \
  --name /quakecstudio/production/example-token --value '...'
```

Terraform reads them and writes the GitHub secret. Map secret names to
parameter names in `terraform.tfvars`:

- environment secrets: `github_secrets` in `dev` / `production`
- repository secrets: `repository_secrets` in `github`

The values end up in Terraform state, which is encrypted in the S3 backend.
The site deploy itself needs no secrets: it authenticates to AWS with OIDC.

## CI

`.github/workflows/terraform.yml` runs `terraform fmt -check` and
`terraform validate` for each environment, plus `terraform test` for the
`static-site`, `visit-counter`, `github-oidc` and `github-repository`
modules against mocked providers, on pull requests and pushes to `main`. It does not plan or apply against AWS.
