# Created by environments/global.
data "aws_iam_role" "deploy" {
  name = "quakecstudio-dev-site-deploy"
}

# Created by environments/global.
data "aws_route53_zone" "site" {
  name = "quakecstudio.com"
}
