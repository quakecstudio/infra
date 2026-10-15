locals {
  repositories = {
    site = {
      description     = "Website for QuakeC Studio, a modern IDE for QuakeC"
      topics          = ["quake", "quakec", "website"]
      has_wiki        = false
      has_projects    = false
      has_discussions = false
    }
    infra = {
      description     = "Terraform for QuakeC Studio's AWS and GitHub infrastructure"
      topics          = ["quake", "quakec", "terraform", "aws"]
      has_wiki        = false
      has_projects    = false
      has_discussions = true
    }
    editor = {
      description     = "QuakeC Studio: a modern IDE for QuakeC, the scripting language of id Software's Quake"
      topics          = ["quake", "quakec", "editor", "ide"]
      has_wiki        = false
      has_projects    = true
      has_discussions = false
    }
    ".github" = {
      description     = "QuakeC Studio organization profile, default community health files and brand assets"
      topics          = ["quakec"]
      has_wiki        = false
      has_projects    = false
      has_discussions = false
    }
  }

  # Flatten repository => { name => parameter } for the SSM lookups.
  secret_parameters = merge([
    for repo, secrets in var.repository_secrets : {
      for name, parameter in secrets : "${repo}/${name}" => {
        repo      = repo
        name      = name
        parameter = parameter
      }
    }
  ]...)
}

# Secret values live in SSM so they never appear in tfvars or the repo.
data "aws_ssm_parameter" "secret" {
  for_each = local.secret_parameters

  name            = each.value.parameter
  with_decryption = true
}

module "repository" {
  source   = "../../modules/github-repository"
  for_each = local.repositories

  name            = each.key
  description     = each.value.description
  homepage_url    = "https://www.quakecstudio.com"
  topics          = each.value.topics
  has_wiki        = each.value.has_wiki
  has_projects    = each.value.has_projects
  has_discussions = each.value.has_discussions
  merge_queue     = true

  secrets = {
    for key, s in local.secret_parameters : s.name => data.aws_ssm_parameter.secret[key].value
    if s.repo == each.key
  }
}
