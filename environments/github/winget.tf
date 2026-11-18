# smoketurnerbot owns WINGET_TOKEN, the classic token komac submits winget
# manifests with. It isn't a member of the organization, so it needs write
# access to the fork to push manifest branches there. The bot has to accept
# the invitation this creates before its first push.
resource "github_repository_collaborator" "winget_bot" {
  repository = module.repository["winget-pkgs"].name
  username   = "smoketurnerbot"
  permission = "push"
}
