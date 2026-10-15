# Account-wide resources. Apply this root before dev and prod: they use
# the deploy roles and hosted zone created here.

locals {
  tags = {
    Project     = "quakecstudio"
    Environment = "global"
    ManagedBy   = "terraform"
    Repository  = "quakecstudio/infra"
  }
}

module "github_oidc" {
  source = "../../modules/github-oidc"

  # quakecstudio/site uses GitHub's immutable subject format, which identifies the
  # owner and repository by ID (gh api repos/quakecstudio/site/actions/oidc/customization/sub).
  subject_prefix = "repo:quakecstudio@343029298/site@1420765651"

  # GitHub Environment => IAM role. dev and prod attach the
  # permissions for their own bucket and distribution.
  roles = {
    dev  = "quakecstudio-dev-site-deploy"
    prod = "quakecstudio-prod-site-deploy"
  }
}

resource "aws_route53_zone" "site" {
  name = "quakecstudio.com"
}
