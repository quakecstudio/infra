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

variable "merge_queue" {
  description = "Require merges to the default branch to go through a merge queue. Required status checks must also run on the merge_group event."
  type        = bool
  default     = false
}

variable "required_status_checks" {
  description = "Status check contexts that must pass before merging to the default branch."
  type        = list(string)
  default     = []
}

variable "required_linear_history" {
  description = "Require a linear history on the default branch (no merge commits)."
  type        = bool
  default     = true
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

variable "allow_auto_merge" {
  description = "Allow auto-merge, which gh pr merge uses to add a PR to the merge queue. GitHub Free only supports it on public repositories."
  type        = bool
  default     = true
}

variable "bypass_actors" {
  description = "Actors that can bypass the default-branch ruleset. Leave actor_id null for actor types without an ID, such as OrganizationAdmin."
  type = list(object({
    actor_type  = string
    actor_id    = optional(number)
    bypass_mode = string
  }))
  default = []
}
