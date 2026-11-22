# Role the publishing repository's workflow assumes through OIDC. It can sync
# the bucket and invalidate the cache, and nothing else.

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
