# Created by environments/global.
data "aws_iam_role" "deploy" {
  name = "quakecstudio-dev-site-deploy"
}

# Created by environments/global.
data "aws_route53_zone" "site" {
  name = "quakecstudio.com"
}

# Secret values live in SSM so they never appear in tfvars or the repo.
data "aws_ssm_parameter" "github_secret" {
  for_each = var.github_secrets

  name            = each.value
  with_decryption = true
}
