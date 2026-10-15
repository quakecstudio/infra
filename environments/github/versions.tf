terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.13"
    }
  }

  # Partial configuration: supply the rest with
  #   terraform init -backend-config=backend.hcl
  # (copy backend.hcl.example to backend.hcl and fill it in).
  backend "s3" {}
}
