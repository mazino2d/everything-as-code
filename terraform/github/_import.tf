# One-off imports for repositories created outside Terraform.
# Delete this file once the apply that imports them has run.

import {
  to = module.curriculum_vitae.github_repository.this
  id = "curriculum-vitae"
}

import {
  to = module.curriculum_vitae.github_branch_default.this[0]
  id = "curriculum-vitae"
}
