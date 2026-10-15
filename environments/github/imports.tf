# The repositories were created by hand; adopt them instead of creating new ones.
# These blocks are no-ops once the resources are in state.

import {
  for_each = local.repositories
  to       = module.repository[each.key].github_repository.this
  id       = each.key
}

import {
  for_each = local.repositories
  to       = module.repository[each.key].github_branch_default.this
  id       = each.key
}
