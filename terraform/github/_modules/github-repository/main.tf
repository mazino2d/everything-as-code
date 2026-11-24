locals {
  # GitHub Free offers secret scanning on public repos only; archived repos are read-only.
  security = {
    dependabot_alerts               = !var.archived && coalesce(var.security.dependabot_alerts, true)
    dependabot_security_updates     = !var.archived && coalesce(var.security.dependabot_security_updates, true)
    secret_scanning                 = !var.archived && coalesce(var.security.secret_scanning, var.visibility == "public")
    private_vulnerability_reporting = !var.archived && var.visibility == "public" && coalesce(var.security.private_vulnerability_reporting, true)
    code_scanning                   = !var.archived && var.visibility == "public" && var.security.code_scanning
  }
}

# GitHub Free has no wiki on private repos (the API silently ignores has_wiki = true),
# so private repos keep it off instead of showing a diff on every plan.
resource "github_repository" "this" {
  name                        = var.name
  description                 = var.description
  visibility                  = var.visibility
  topics                      = var.topics
  has_issues                  = var.has_issues
  has_wiki                    = var.has_wiki && var.visibility == "public"
  has_projects                = var.has_projects
  has_discussions             = var.has_discussions
  allow_merge_commit          = var.allow_merge_commit
  allow_squash_merge          = var.allow_squash_merge
  allow_rebase_merge          = var.allow_rebase_merge
  allow_auto_merge            = var.allow_auto_merge != null ? var.allow_auto_merge : try(var.branch_protection.required_status_checks, null) != null
  squash_merge_commit_title   = "PR_TITLE"
  squash_merge_commit_message = "PR_BODY"
  is_template                 = var.is_template
  delete_branch_on_merge      = var.delete_branch_on_merge
  archived                    = var.archived
  auto_init                   = false

  dynamic "security_and_analysis" {
    for_each = local.security.secret_scanning ? [1] : []
    content {
      secret_scanning {
        status = "enabled"
      }
      secret_scanning_push_protection {
        status = "enabled"
      }
    }
  }
}

resource "github_repository_vulnerability_alerts" "this" {
  count      = local.security.dependabot_alerts ? 1 : 0
  repository = github_repository.this.name
  enabled    = true
}

# Security updates open PRs for vulnerable dependencies; they need alerts on.
resource "github_repository_dependabot_security_updates" "this" {
  count      = local.security.dependabot_security_updates ? 1 : 0
  repository = github_repository.this.name
  enabled    = true

  depends_on = [github_repository_vulnerability_alerts.this]
}

# integrations/github has no resource for private vulnerability reporting, so the
# generic REST provider manages the endpoint; plans read it back, so a manual
# change on GitHub shows up as drift.
resource "restful_resource" "private_vulnerability_reporting" {
  count = local.security.private_vulnerability_reporting ? 1 : 0

  path          = "/repos/${github_repository.this.full_name}/private-vulnerability-reporting"
  create_method = "PUT"
  update_method = "PUT"
  delete_method = "DELETE"
  body          = { enabled = true }
}

# CodeQL default setup (GitHub picks the languages). It cannot run alongside an
# advanced setup workflow that uploads CodeQL results, so leave it off for those repos.
resource "restful_resource" "code_scanning" {
  count = local.security.code_scanning ? 1 : 0

  path          = "/repos/${github_repository.this.full_name}/code-scanning/default-setup"
  create_method = "PATCH"
  update_method = "PATCH"
  delete_method = "PATCH"
  body          = { state = "configured" }
  delete_body   = { state = "not-configured" }
}

resource "github_repository_pages" "this" {
  count      = var.pages != null ? 1 : 0
  repository = github_repository.this.name
  build_type = try(var.pages.build_type, null)
  cname      = try(var.pages.cname, null)

  dynamic "source" {
    for_each = var.pages != null && var.pages.build_type != "workflow" ? [var.pages] : []
    content {
      branch = source.value.branch
      path   = source.value.path
    }
  }
}

resource "github_branch_default" "this" {
  count      = var.archived || !var.initialized ? 0 : 1
  repository = github_repository.this.name
  branch     = var.default_branch
  rename     = var.rename_default_branch
}

# Private repos on GitHub Free cannot have branch protection; pass branch_protection = null to skip it.
resource "github_branch_protection" "this" {
  count                           = var.archived || !var.initialized || var.branch_protection == null ? 0 : 1
  repository_id                   = github_repository.this.node_id
  pattern                         = var.default_branch
  enforce_admins                  = var.branch_protection.enforce_admins
  require_conversation_resolution = var.branch_protection.require_conversation_resolution
  required_linear_history         = var.branch_protection.required_linear_history

  dynamic "required_status_checks" {
    for_each = var.branch_protection.required_status_checks == null ? [] : [var.branch_protection.required_status_checks]
    content {
      strict   = required_status_checks.value.strict
      contexts = required_status_checks.value.contexts
    }
  }

  required_pull_request_reviews {
    required_approving_review_count = var.branch_protection.required_approving_review_count
    dismiss_stale_reviews           = var.branch_protection.dismiss_stale_reviews
  }
}

resource "github_actions_variable" "eac_deployer_app_id" {
  count         = var.deploy_app != null ? 1 : 0
  repository    = github_repository.this.name
  variable_name = "EAC_DEPLOYER_APP_ID"
  value         = var.deploy_app.app_id
}

resource "github_actions_secret" "eac_deployer_private_key" {
  count       = var.deploy_app != null ? 1 : 0
  repository  = github_repository.this.name
  secret_name = "EAC_DEPLOYER_PRIVATE_KEY"
  value       = var.deploy_app.private_key
}

resource "github_workflow_repository_permissions" "this" {
  count                            = var.actions_can_create_and_approve_pull_requests ? 1 : 0
  repository                       = github_repository.this.name
  default_workflow_permissions     = "read"
  can_approve_pull_request_reviews = true
}
