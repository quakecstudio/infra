# The Azure Trusted Signing account, its app registration and the editor's
# federated credential live in smoketurner-infra's azure root, shared with
# quack and precipitate.
data "terraform_remote_state" "azure" {
  backend = "s3"

  config = {
    profile = "root-admin"
    bucket  = "terraform-state-860114833029-us-east-1"
    key     = "azure/terraform.tfstate"
    region  = "us-east-1"
  }
}
