locals {
  project     = "quakecstudio"
  environment = "dev"
  name        = "${local.project}-${local.environment}"

  tags = {
    Project     = local.project
    Environment = local.environment
    ManagedBy   = "terraform"
    Repository  = "quakecstudio/infra"
  }
}
