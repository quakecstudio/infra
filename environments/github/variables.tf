variable "aws_region" {
  description = "Region of the SSM parameters that hold secret values."
  type        = string
  default     = "us-east-1"
}

variable "repository_secrets" {
  description = "Repository-level Actions secrets: repository => { SECRET_NAME = \"<SSM SecureString parameter name>\" }."
  type        = map(map(string))
  default     = {}
}
