variable "name" {
  description = "Repository name (without owner)."
  type        = string
}

variable "description" {
  description = "Repository description."
  type        = string
}

variable "homepage_url" {
  description = "Website shown on the repository page."
  type        = string
  default     = null
}

variable "topics" {
  description = "Repository topics."
  type        = list(string)
  default     = []
}

variable "visibility" {
  description = "public or private."
  type        = string
  default     = "public"
}

variable "has_issues" {
  description = "Enable issues."
  type        = bool
  default     = true
}

variable "has_wiki" {
  description = "Enable the wiki."
  type        = bool
  default     = false
}

variable "has_projects" {
  description = "Enable projects."
  type        = bool
  default     = false
}

variable "has_discussions" {
  description = "Enable discussions."
  type        = bool
  default     = false
}

variable "default_branch" {
  description = "Default branch. It must already exist."
  type        = string
  default     = "main"
}

variable "protect_default_branch" {
  description = "Add a ruleset that blocks deleting and force-pushing the default branch."
  type        = bool
  default     = true
}

variable "require_pull_request" {
  description = "Require changes to the default branch to go through a pull request."
  type        = bool
  default     = false
}

variable "required_status_checks" {
  description = "Status check contexts that must pass before merging to the default branch."
  type        = list(string)
  default     = []
}

variable "secrets" {
  description = "Repository-level Actions secrets, by name. Values are stored (encrypted) in Terraform state."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "variables" {
  description = "Repository-level Actions variables, by name."
  type        = map(string)
  default     = {}
}
