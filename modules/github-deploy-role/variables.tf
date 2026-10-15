variable "name" {
  description = "Name of the IAM role."
  type        = string
}

variable "github_repository" {
  description = "Repository allowed to assume the role, as \"owner/repo\"."
  type        = string
}

variable "github_environment" {
  description = "GitHub Actions environment the deploy job runs in. Only jobs in this environment can assume the role."
  type        = string
}

variable "create_oidc_provider" {
  description = "Create the GitHub Actions OIDC provider. Only one can exist per AWS account; set false and pass oidc_provider_arn if it already exists."
  type        = bool
  default     = true
}

variable "oidc_provider_arn" {
  description = "ARN of an existing GitHub Actions OIDC provider. Used when create_oidc_provider is false."
  type        = string
  default     = null
}

variable "bucket_arn" {
  description = "ARN of the site bucket the role may write to."
  type        = string
}

variable "distribution_arn" {
  description = "ARN of the CloudFront distribution the role may invalidate."
  type        = string
}

variable "tags" {
  description = "Tags applied to every resource in the module."
  type        = map(string)
  default     = {}
}
