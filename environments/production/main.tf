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

  api_origin = {
    domain_name   = module.visit_counter.function_url_domain_name
    function_name = module.visit_counter.function_name
  }
  force_destroy = false

  deploy_role_name = data.aws_iam_role.deploy.name
}

module "visit_counter" {
  source = "../../modules/visit-counter"

  name                 = local.name
  reserved_concurrency = 5
}

# Secret values live in SSM so they never appear in tfvars or the repo.
data "aws_ssm_parameter" "github_secret" {
  for_each = var.github_secrets

  name            = each.value
  with_decryption = true
}

module "github_environment" {
  source = "../../modules/github-environment"

  repository  = split("/", var.github_repository)[1]
  environment = local.environment

  # Production deploys only from main, after approval by jplock.
  deployment_branches = ["main"]
  reviewer_user_ids   = [49093]

  # Read by quakecstudio/site's deploy workflow.
  variables = {
    AWS_REGION                 = var.aws_region
    AWS_DEPLOY_ROLE_ARN        = data.aws_iam_role.deploy.arn
    SITE_BUCKET                = module.site.bucket_name
    CLOUDFRONT_DISTRIBUTION_ID = module.site.distribution_id
    SITE_URL                   = module.site.site_url
  }

  secrets = { for name, p in data.aws_ssm_parameter.github_secret : name => p.value }
}
