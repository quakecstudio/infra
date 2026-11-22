# Only used to read the bot token from SSM Parameter Store.
provider "aws" {
  profile = "quakecstudio-admin"
  region  = var.aws_region
}

provider "discord" {
  token            = data.aws_ssm_parameter.bot_token.value
  audit_log_reason = "Managed by Terraform (quakecstudio/infra)"
}
