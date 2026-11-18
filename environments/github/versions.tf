terraform {
  required_version = ">= 1.10"

  backend "s3" {
    profile      = "quakecstudio-admin"
    bucket       = "terraform-state-663345616657-us-east-1-an"
    key          = "github/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.13"
    }
    gpg = {
      source  = "terraform-provider-gpg/gpg"
      version = "~> 0.2.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.4"
    }
  }
}
