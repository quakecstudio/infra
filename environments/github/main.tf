module "repository" {
  source   = "../../modules/github-repository"
  for_each = local.repositories

  name                   = each.key
  description            = each.value.description
  homepage_url           = "https://www.quakecstudio.com"
  topics                 = each.value.topics
  visibility             = lookup(each.value, "visibility", "public")
  fork_of                = lookup(each.value, "fork_of", null)
  default_branch         = lookup(each.value, "default_branch", "main")
  has_issues             = lookup(each.value, "has_issues", true)
  has_wiki               = each.value.has_wiki
  has_projects           = each.value.has_projects
  has_discussions        = each.value.has_discussions
  merge_queue            = lookup(each.value, "merge_queue", true)
  require_pull_request   = lookup(each.value, "require_pull_request", false)
  bypass_actors          = lookup(each.value, "bypass_actors", [])
  protect_default_branch = lookup(each.value, "protect_default_branch", true)
  allow_auto_merge       = lookup(each.value, "allow_auto_merge", true)

  required_status_checks = lookup(each.value, "required_status_checks", [])

  secrets = {
    for key, s in local.secret_parameters : s.name => data.aws_ssm_parameter.secret[key].value
    if s.repo == each.key
  }
}
