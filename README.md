# QuakeC Studio — infra

Terraform for the QuakeC Studio website: a private S3 bucket served through
CloudFront. The page itself lives in
[`quakecstudio/site`](https://github.com/quakecstudio/site). It also serves
the package repository at packages.quakecstudio.com and manages the
organization's GitHub repositories.

```
modules/
├── static-site/          # S3 bucket + CloudFront (OAC), security headers,
│                         # optional ACM cert + Route 53 records
├── packages/             # APT and YUM/DNF repository: S3 bucket + CloudFront,
│                         # ACM cert, Route 53 records, OIDC publish role
├── visit-counter/        # Lambda + DynamoDB visitor counter at /api/visit
├── github-oidc/          # GitHub Actions OIDC provider + per-environment deploy roles
├── github-environment/   # GitHub Environment, deploy branch rules, Actions
│                         # variables and secrets
└── github-repository/    # Repository settings, default branch, branch
                          # ruleset, repo-level Actions variables and secrets
environments/
├── global/               # account-wide: quakecstudio.com hosted zone, GitHub
│                         # OIDC provider and deploy roles
├── github/               # organization profile and every quakecstudio repository
├── dev/                  # site + its "dev" GitHub Environment in quakecstudio/site
└── prod/                 # site + its "prod" GitHub Environment, and
                          # packages.quakecstudio.com
```

Each environment is its own Terraform root with its own state. Apply
`global` first: `dev` and `prod` look up the deploy roles and hosted zone it
creates. Apply `github` before `prod`, which looks up the `packages`
repository.

## Requirements

- Terraform >= 1.10 (S3 backend uses native lockfile locking)
- AWS provider ~> 6.0
- A GitHub token that can administer the `quakecstudio` repositories, in
  `GITHUB_TOKEN` (e.g. `GITHUB_TOKEN=$(gh auth token)`), for every root
  except `global`
- The `quakecstudio-admin` AWS profile

State is stored in the `terraform-state-663345616657-us-east-1-an` S3 bucket
(us-east-1) under `<environment>/terraform.tfstate`. Both the backend and the
AWS provider use the `quakecstudio-admin` AWS profile.

## Usage

`ENV` selects the environment and defaults to `global`.

```sh
make init ENV=global
make apply ENV=global

make init ENV=prod
GITHUB_TOKEN=$(gh auth token) make plan ENV=prod
GITHUB_TOKEN=$(gh auth token) make apply ENV=prod
```

`global` creates the `quakecstudio.com` Route 53 hosted zone; the registrar
must use its name servers (the `name_servers` output). `dev` serves
`dev.quakecstudio.com`: it looks the zone up, and the `static-site` module
requests and DNS-validates an ACM certificate in us-east-1 and creates
`A`/`AAAA` aliases. `prod` does the same for `www.quakecstudio.com`, and
`quakecstudio.com` redirects there (301, path kept) through an S3 bucket with
redirect-all website hosting behind its own CloudFront distribution for HTTPS.

### Deploy roles

`environments/global` creates the account's GitHub Actions OIDC provider and
one IAM role per GitHub Environment: `quakecstudio-dev-site-deploy` and
`quakecstudio-prod-site-deploy`. Each role only trusts jobs from
`quakecstudio/site` running in the matching Environment
(`repo:quakecstudio@343029298/site@1420765651:environment:<env>`, GitHub's
immutable subject format) and has no permissions of its own.
`dev` and `prod` look their role up and attach an inline policy that
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

## Packages

`prod` runs `modules/packages` for `packages.quakecstudio.com`, the APT and
YUM/DNF repository: a private S3 bucket behind CloudFront, with its own ACM
certificate and `A`/`AAAA` aliases. The packages and their signed metadata
live in [`quakecstudio/packages`](https://github.com/quakecstudio/packages),
whose workflow syncs the checkout to the bucket and invalidates the cache on
every push to `main`. Request paths reach S3 unchanged, since APT and DNF
fetch extensionless files such as `dists/stable/InRelease`.

The workflow assumes the `quakecstudio-packages-publish` role through OIDC.
The role only trusts runs on `main` of that repository, identified by its
immutable owner and repository IDs, and can only write to the bucket and
invalidate the distribution. `prod` sets what the workflow reads on the
repository:

| Name                       | Kind     | Source           |
| -------------------------- | -------- | ---------------- |
| `ASSUME_ROLE_ARN`          | secret   | the publish role |
| `PACKAGES_BUCKET`          | variable | the bucket       |
| `PACKAGES_DISTRIBUTION_ID` | variable | the distribution |

### Release secrets

`environments/github` creates everything the editor's release workflow needs
to publish, as Actions secrets on `quakecstudio/editor`:

| Secret                               | What it is                                              |
| ------------------------------------ | ------------------------------------------------------- |
| `PACKAGES_DEPLOY_KEY`                | SSH private key with write access to `packages`         |
| `HOMEBREW_TAP_DEPLOY_KEY`            | SSH private key with write access to `homebrew-tap`     |
| `GPG_PRIVATE_KEY`, `GPG_PASSPHRASE`  | key that signs the RPMs and the repository metadata     |

Terraform generates each key pair. The SSH public halves are deploy keys on
the two repositories; the workflow checks them out with `ssh-key` and pushes
to `main`. Pushes made with a deploy key start the target repository's
workflows, which a `GITHUB_TOKEN` push would not. The organization has to
allow deploy keys, a setting the GitHub provider can't manage:

```sh
gh api -X PATCH orgs/quakecstudio -F deploy_keys_enabled_for_repositories=true
```

The signing key's public
half and fingerprint are outputs of the root, and `quakecstudio/packages`
publishes the key as `gpg/quakecstudio.asc`:

```sh
terraform -chdir=environments/github output -raw packages_gpg_public_key \
  > ../packages/gpg/quakecstudio.asc
```

The signing key comes from the community
[`terraform-provider-gpg/gpg`](https://registry.terraform.io/providers/terraform-provider-gpg/gpg/latest)
provider (Curve25519). Replacing it means every user has to trust the new
public key.

### winget

The editor's release workflow submits each release to winget with
[komac](https://github.com/russellbanks/Komac), which pushes a manifest branch
to a fork of `microsoft/winget-pkgs` and opens a pull request from it.
`environments/github` creates that fork as `quakecstudio/winget-pkgs`
(`KOMAC_FORK_OWNER: quakecstudio`) and sets `WINGET_TOKEN` on
`quakecstudio/editor`.

The token can't be generated by Terraform: opening a pull request on a
repository the organization doesn't own needs a user identity. It is a classic
personal access token with the `public_repo` and `workflow` scopes (komac
can't open the pull request with a fine-grained one, and without `workflow` it
can't sync the fork past upstream commits that change a workflow), owned by
`smoketurnerbot`, which must have signed Microsoft's CLA. `environments/github` gives that account write access
to the fork; it has to accept the invitation once. The token is stored in SSM:

```sh
aws ssm put-parameter --profile quakecstudio-admin --type SecureString \
  --name /quakecstudio/github/editor/winget-token --value '...'
```

komac can only update a package that already exists in `microsoft/winget-pkgs`,
so the first version is submitted by hand, once, with `komac new`.

## GitHub

All GitHub configuration is managed here with the
[`integrations/github`](https://registry.terraform.io/providers/integrations/github/latest)
provider; don't change these settings in the GitHub UI.

### Deploy environments

`dev` and `prod` each create the matching GitHub Environment in
`quakecstudio/site` and set the Actions variables its deploy workflow reads,
straight from their own resources:

| Variable                     | Source                     |
| ---------------------------- | -------------------------- |
| `AWS_REGION`                 | `var.aws_region`           |
| `AWS_DEPLOY_ROLE_ARN`        | the deploy role            |
| `SITE_BUCKET`                | the site bucket            |
| `CLOUDFRONT_DISTRIBUTION_ID` | the distribution           |
| `SITE_URL`                   | the site URL               |

The `prod` Environment only accepts deploys from `main`, and each
prod deploy waits for approval from jplock. The deploy role
only trusts jobs from `quakecstudio/site` running in the matching Environment.

### Repositories

`environments/github` manages the organization's profile and member defaults
(`organization.tf`), and the `site`, `infra`, `editor`, `.github`,
`tree-sitter-quakec`, `kb`, `packages`, `homebrew-tap` and `winget-pkgs`
repositories:
description, homepage (https://www.quakecstudio.com) and
topics, features (issues on everywhere; wiki, projects and discussions on for
`editor`; discussions on for `infra`), squash-only
merges with branch deletion after merge, Dependabot alerts off, `main` as the
default branch, and a ruleset that blocks deleting or force-pushing it and
sends merges through a merge queue. Workflows that provide required status
checks must also run on `merge_group`. `packages` and `homebrew-tap` have no
merge queue: the editor's release workflow pushes to `main` in both.
`winget-pkgs` is a fork of `microsoft/winget-pkgs` with an unprotected
`master`.
Removing one from Terraform archives it rather than deleting it. Changing the
organization settings needs the `admin:org` token scope:

```sh
gh auth refresh -h github.com -s admin:org
make init ENV=github
GITHUB_TOKEN=$(gh auth token) make plan ENV=github
```

### Secrets

Secret values live in SSM Parameter Store as `SecureString` parameters, created
outside Terraform so they never appear in tfvars or the repo:

```sh
aws ssm put-parameter --profile quakecstudio-admin --type SecureString \
  --name /quakecstudio/prod/example-token --value '...'
```

Terraform reads them and writes the GitHub secret. Map secret names to
parameter names:

- environment secrets: `github_secrets` in the `terraform.tfvars` of `dev` /
  `prod`
- repository secrets: `local.repository_secrets` in
  `environments/github/main.tf`. A parameter listed there must exist, or every
  plan of that root fails.

The values end up in Terraform state, which is encrypted in the S3 backend.
The site deploy itself needs no secrets: it authenticates to AWS with OIDC.

## CI

`.github/workflows/terraform.yml` runs `terraform fmt -check` and
`terraform validate` for each environment, plus `terraform test` for the
`static-site`, `packages`, `visit-counter`, `github-oidc` and `github-repository`
modules against mocked providers, on pull requests and pushes to `main`. It does not plan or apply against AWS.
