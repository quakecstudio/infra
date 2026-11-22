# Lets the deploy role upload content and invalidate the cache, and nothing else.

resource "aws_iam_role_policy" "deploy" {
  count = var.deploy_role_name != null ? 1 : 0

  name   = "${var.name}-deploy-site"
  role   = var.deploy_role_name
  policy = data.aws_iam_policy_document.deploy[0].json
}
