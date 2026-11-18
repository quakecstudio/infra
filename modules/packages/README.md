# packages

An APT and YUM/DNF package repository served from a private S3 bucket through
CloudFront at one custom hostname, with an ACM certificate and Route 53 alias
records, plus the IAM role a GitHub repository's workflow assumes through OIDC
to publish it.

The publishing repository holds the packages and their signed metadata in git;
its workflow syncs the checkout to the bucket and invalidates the cache. Only
runs on that repository's default branch can assume the role, which can write
to this bucket and invalidate this distribution and nothing else.

Unlike `static-site`, the distribution passes request paths to S3 unchanged:
APT and DNF fetch extensionless files such as `dists/stable/InRelease`.
