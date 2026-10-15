variable "name" {
  description = "Name prefix for all resources, e.g. \"quakecstudio-prod\"."
  type        = string
}

variable "reserved_concurrency" {
  description = "Maximum concurrent executions. Caps cost if someone floods the endpoint; excess requests get 429s. null reserves none."
  type        = number
  default     = 5
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention for the function."
  type        = number
  default     = 14
}

variable "tags" {
  description = "Tags applied to every resource in the module."
  type        = map(string)
  default     = {}
}
