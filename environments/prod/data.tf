# Created by environments/global.
data "aws_iam_role" "deploy" {
  name = "quakecstudio-prod-site-deploy"
}

# Created by environments/global.
data "aws_route53_zone" "site" {
  name = "quakecstudio.com"
}

# Created by environments/global.
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# Created by environments/github.
data "github_repository" "packages" {
  name = "packages"
}
