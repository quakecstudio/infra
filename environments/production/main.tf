locals {
  project     = "quakecstudio"
  environment = "production"
  name        = "${local.project}-${local.environment}"

  tags = {
    Project     = local.project
    Environment = local.environment
    ManagedBy   = "terraform"
    Repository  = "quakecstudio/infra"
  }
}

module "site" {
  source = "../../modules/static-site"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  name            = local.name
  domain_names    = var.domain_names
  route53_zone_id = var.route53_zone_id
  price_class     = "PriceClass_100"
  force_destroy   = false
}

module "deploy_role" {
  source = "../../modules/github-deploy-role"

  name                 = "${local.name}-site-deploy"
  github_repository    = var.github_repository
  github_environment   = local.environment
  create_oidc_provider = var.create_github_oidc_provider
  oidc_provider_arn    = var.github_oidc_provider_arn
  bucket_arn           = module.site.bucket_arn
  distribution_arn     = module.site.distribution_arn
}
