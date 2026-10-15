# Only used to read secret values from SSM Parameter Store.
provider "aws" {
  profile = "quakecstudio-admin"
  region  = var.aws_region
}

# Authenticates with GITHUB_TOKEN, e.g. GITHUB_TOKEN=$(gh auth token).
provider "github" {
  owner = "quakecstudio"
}
