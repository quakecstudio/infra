variable "aws_region" {
  description = "Region for the S3 bucket and IAM resources."
  type        = string
  default     = "us-east-1"
}

variable "domain_names" {
  description = "Custom hostnames for the site (first is primary). Empty uses the *.cloudfront.net domain."
  type        = list(string)
  default     = []
}

variable "route53_zone_id" {
  description = "Route 53 hosted zone for domain_names."
  type        = string
  default     = null
}

variable "github_repository" {
  description = "Repository that deploys the site content."
  type        = string
  default     = "quakecstudio/site"
}

variable "create_github_oidc_provider" {
  description = "Create the account-wide GitHub Actions OIDC provider. Set false if another environment in this account already created it."
  type        = bool
  default     = true
}

variable "github_oidc_provider_arn" {
  description = "Existing GitHub Actions OIDC provider ARN, when create_github_oidc_provider is false."
  type        = string
  default     = null
}
