variable "name" {
  description = "Name prefix for all resources, e.g. \"quakecstudio-production\"."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,40}[a-z0-9]$", var.name))
    error_message = "name must be 3-42 characters of lowercase letters, digits and hyphens."
  }
}

variable "domain_names" {
  description = "Custom hostnames for the site (first is primary). Leave empty to use the default *.cloudfront.net domain."
  type        = list(string)
  default     = []
}

variable "route53_zone_id" {
  description = "Route 53 hosted zone that serves domain_names. Required when domain_names is set; used for ACM validation and alias records."
  type        = string
  default     = null
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

variable "content_security_policy" {
  description = "Content-Security-Policy header sent with every response."
  type        = string
  default     = "default-src 'none'; script-src 'self'; style-src 'self'; img-src 'self' data:; font-src 'self'; connect-src 'self'; manifest-src 'self'; base-uri 'self'; form-action 'self'; frame-ancestors 'none'; upgrade-insecure-requests"
}

variable "force_destroy" {
  description = "Allow the content bucket to be destroyed while it still contains objects."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to every resource in the module."
  type        = map(string)
  default     = {}
}

variable "api_origin" {
  description = "Optional Lambda function URL served at /api/* (uncached). CloudFront signs requests with origin access control and is granted permission to invoke the function."
  type = object({
    domain_name   = string # function URL hostname, e.g. abc123.lambda-url.us-east-1.on.aws
    function_name = string
  })
  default = null
}
