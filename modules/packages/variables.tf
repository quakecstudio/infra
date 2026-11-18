variable "name" {
  description = "Name prefix for all resources, e.g. \"quakecstudio-packages\"."
  type        = string

  validation {
    # The bucket name adds the 26-character account-regional suffix, within
    # S3's 63-character limit.
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,34}[a-z0-9]$", var.name))
    error_message = "name must be 3-36 characters of lowercase letters, digits and hyphens."
  }
}

variable "domain_name" {
  description = "Hostname the package repository is served at, e.g. \"packages.quakecstudio.com\"."
  type        = string
}

variable "route53_zone_id" {
  description = "Route 53 hosted zone that serves domain_name; used for ACM validation and alias records."
  type        = string
}

variable "price_class" {
  description = "CloudFront price class."
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.price_class)
    error_message = "price_class must be PriceClass_100, PriceClass_200 or PriceClass_All."
  }
}

variable "github_oidc_provider_arn" {
  description = "ARN of the account's GitHub Actions OIDC provider."
  type        = string
}

variable "github_subject_prefix" {
  description = "Immutable OIDC sub claim prefix of the repository allowed to publish, as \"repo:<owner>@<owner-id>/<repo>@<repo-id>\". Only its default branch can assume the publish role."
  type        = string
}

variable "github_default_branch" {
  description = "Branch of the publishing repository whose workflow runs can assume the publish role."
  type        = string
  default     = "main"
}

variable "tags" {
  description = "Tags applied to every resource in the module."
  type        = map(string)
  default     = {}
}
