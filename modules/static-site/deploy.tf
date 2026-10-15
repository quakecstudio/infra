# Lets the deploy role upload content and invalidate the cache, and nothing else.

data "aws_iam_policy_document" "deploy" {
  count = var.deploy_role_name != null ? 1 : 0

  statement {
    sid       = "ListBucket"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.site.arn]
  }

  statement {
    sid       = "WriteObjects"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]
  }

  statement {
    sid       = "InvalidateCache"
    actions   = ["cloudfront:CreateInvalidation", "cloudfront:GetInvalidation"]
    resources = [aws_cloudfront_distribution.site.arn]
  }
}

resource "aws_iam_role_policy" "deploy" {
  count = var.deploy_role_name != null ? 1 : 0

  name   = "${var.name}-deploy-site"
  role   = var.deploy_role_name
  policy = data.aws_iam_policy_document.deploy[0].json
}
