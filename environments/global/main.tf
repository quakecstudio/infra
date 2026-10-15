# Account-wide resources. Apply this root before dev and production: they look
# up the deploy roles created here.

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

  github_repository = "quakecstudio/site"

  # GitHub Environment => IAM role. dev and production attach the
  # permissions for their own bucket and distribution.
  roles = {
    dev        = "quakecstudio-dev-site-deploy"
    production = "quakecstudio-production-site-deploy"
  }
}
