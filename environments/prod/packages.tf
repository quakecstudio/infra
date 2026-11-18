# packages.quakecstudio.com: the APT and YUM/DNF repository published from
# quakecstudio/packages. Apply environments/github first: it creates that
# repository, whose ID the publish role's trust policy pins.

module "packages" {
  source = "../../modules/packages"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  name            = "${local.project}-packages"
  domain_name     = "packages.quakecstudio.com"
  route53_zone_id = data.aws_route53_zone.site.zone_id

  github_oidc_provider_arn = data.aws_iam_openid_connect_provider.github.arn

  # GitHub's immutable subject format: 343029298 is the quakecstudio
  # organization (gh api repos/quakecstudio/packages/actions/oidc/customization/sub).
  github_subject_prefix = "repo:quakecstudio@343029298/packages@${data.github_repository.packages.repo_id}"
}

# Read by quakecstudio/packages' publish workflow.
resource "github_actions_secret" "packages_assume_role_arn" {
  repository  = data.github_repository.packages.name
  secret_name = "ASSUME_ROLE_ARN"
  value       = module.packages.publish_role_arn
}

resource "github_actions_variable" "packages" {
  for_each = {
    PACKAGES_BUCKET          = module.packages.bucket_name
    PACKAGES_DISTRIBUTION_ID = module.packages.distribution_id
  }

  repository    = data.github_repository.packages.name
  variable_name = each.key
  value         = each.value
}
