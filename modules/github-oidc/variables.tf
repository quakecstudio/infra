variable "subject_prefix" {
  description = "Immutable OIDC sub claim prefix of the repository allowed to assume the roles, as \"repo:<owner>@<owner-id>/<repo>@<repo-id>\"."
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
