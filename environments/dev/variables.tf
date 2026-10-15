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
  description = "Repository that deploys the site content, as \"owner/repo\"."
  type        = string
  default     = "quakecstudio/site"
}

variable "github_secrets" {
  description = "Extra Actions secrets for this GitHub Environment: { SECRET_NAME = \"<SSM SecureString parameter name>\" }."
  type        = map(string)
  default     = {}
}
