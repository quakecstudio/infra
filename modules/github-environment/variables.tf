variable "repository" {
  description = "Repository name (without owner) the environment belongs to."
  type        = string
}

variable "environment" {
  description = "GitHub Environment name."
  type        = string
}

variable "variables" {
  description = "Actions variables to set on the environment, by name."
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Actions secrets to set on the environment, by name. Values are stored (encrypted) in Terraform state."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "reviewer_user_ids" {
  description = "GitHub user IDs that must approve deployments. Empty means no approval."
  type        = list(number)
  default     = []
}

variable "deployment_branches" {
  description = "Branch name patterns allowed to deploy. Empty means any branch."
  type        = list(string)
  default     = []
}
