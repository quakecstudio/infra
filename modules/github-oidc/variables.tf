variable "github_repository" {
  description = "Repository allowed to assume the roles, as \"owner/repo\"."
  type        = string
}

variable "roles" {
  description = "Deploy roles to create: GitHub Environment name => IAM role name. Only jobs running in that Environment can assume the role."
  type        = map(string)
}

variable "tags" {
  description = "Tags applied to every resource in the module."
  type        = map(string)
  default     = {}
}
