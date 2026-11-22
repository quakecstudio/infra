locals {
  project     = "quakecstudio"
  environment = "prod"
  name        = "${local.project}-${local.environment}"

  tags = {
    Project     = local.project
    Environment = local.environment
    ManagedBy   = "terraform"
    Repository  = "quakecstudio/infra"
  }
}
