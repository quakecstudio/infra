# github-oidc

The account's GitHub Actions OIDC provider and one IAM deploy role per GitHub
Environment. No long-lived AWS keys.

Each role's trust policy only accepts tokens for
`<subject_prefix>:environment:<environment>`, so the workflow job must declare
that `environment:`. `subject_prefix` is the repository's immutable OIDC subject
prefix, `repo:<owner>@<owner-id>/<repo>@<repo-id>`, which GitHub reports at
`gh api repos/<owner>/<repo>/actions/oidc/customization/sub`. IDs, unlike names,
can't be reused if the repository is renamed or deleted and recreated.

The roles have no permissions of their own. The environment roots look their
role up with `data "aws_iam_role"` and attach inline policies scoped to their
own resources (see `deploy_role_name` on `modules/static-site`).

Only one GitHub OIDC provider can exist per AWS account, which is why this
lives in `environments/global`.
