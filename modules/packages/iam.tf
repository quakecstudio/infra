# Role the publishing repository's workflow assumes through OIDC. It can sync
# the bucket and invalidate the cache, and nothing else.

locals {
  oidc_host = "token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "publish_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.github_oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Owner and repository IDs, unlike names, can't be reused if the repository
    # is renamed or deleted and recreated.
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:sub"
      values   = ["${var.github_subject_prefix}:ref:refs/heads/${var.github_default_branch}"]
    }
  }
}

data "aws_iam_policy_document" "publish" {
  statement {
    sid       = "ListBucket"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.packages.arn]
  }

  statement {
    sid       = "WriteObjects"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.packages.arn}/*"]
  }

  statement {
    sid       = "InvalidateCache"
    actions   = ["cloudfront:CreateInvalidation", "cloudfront:GetInvalidation"]
    resources = [aws_cloudfront_distribution.packages.arn]
  }
}

resource "aws_iam_role" "publish" {
  name                 = "${var.name}-publish"
  description          = "GitHub Actions publishes for ${var.github_subject_prefix} (${var.github_default_branch})"
  assume_role_policy   = data.aws_iam_policy_document.publish_trust.json
  max_session_duration = 3600
  tags                 = var.tags
}

resource "aws_iam_role_policy" "publish" {
  name   = "${var.name}-publish"
  role   = aws_iam_role.publish.name
  policy = data.aws_iam_policy_document.publish.json
}
