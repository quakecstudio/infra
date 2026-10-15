# visit-counter

A site-wide visitor counter: a Node.js Lambda function with a DynamoDB table,
reached through CloudFront at `/api/visit`.

| Request          | Effect                                   |
| ---------------- | ---------------------------------------- |
| `GET /api/visit` | `{ "count": N }`                         |
| `POST /api/visit`| atomically adds one, returns the new `N` |

The function URL uses `AWS_IAM` auth. The `static-site` module adds it as a
CloudFront origin with Lambda origin access control and grants CloudFront
permission to invoke it, so the URL can't be called directly.

Concurrency is reserved at `reserved_concurrency` (default 5), which caps how
much a flood of requests can cost; extra requests get throttled.

Lambda requires at least 10 unreserved concurrent executions to remain in the
account. New AWS accounts can start with a total quota of 10, in which case
reserving any fails; request a quota increase (Service Quotas → Lambda →
Concurrent executions) first.

The function's code is `src/index.mjs`; Terraform zips and deploys it.
