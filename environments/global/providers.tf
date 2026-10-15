provider "aws" {
  profile = "quakecstudio-admin"
  region  = var.aws_region

  default_tags {
    tags = local.tags
  }
}
