# github-deploy-role

IAM role that a GitHub Actions job assumes through OIDC to upload a static
site to S3 and invalidate its CloudFront distribution. No long-lived AWS keys.

The trust policy only accepts tokens for
`repo:<github_repository>:environment:<github_environment>`, so the deploy
job must declare that `environment:`.

Only one GitHub OIDC provider can exist per AWS account. The first
environment in an account creates it (`create_oidc_provider = true`);
others set `create_oidc_provider = false` and pass `oidc_provider_arn`.

Permissions: `s3:ListBucket` on the bucket, `s3:GetObject`/`PutObject`/
`DeleteObject` on its objects, and `cloudfront:CreateInvalidation`/
`GetInvalidation` on the distribution.
