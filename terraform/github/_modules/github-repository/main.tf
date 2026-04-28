resource "github_repository" "this" {
  name                        = var.name
  description                 = var.description
  visibility                  = var.visibility
  topics                      = var.topics
  has_issues                  = var.has_issues
  has_wiki                    = var.has_wiki
  has_projects                = var.has_projects
  has_discussions             = var.has_discussions
  allow_merge_commit          = var.allow_merge_commit
  allow_squash_merge          = var.allow_squash_merge
  allow_rebase_merge          = var.allow_rebase_merge
  allow_auto_merge            = var.allow_auto_merge != null ? var.allow_auto_merge : var.branch_protection.required_status_checks != null
  squash_merge_commit_title   = "PR_TITLE"
  squash_merge_commit_message = "PR_BODY"
  is_template                 = var.is_template
  delete_branch_on_merge      = var.delete_branch_on_merge
  archived                    = var.archived
  auto_init                   = false

  lifecycle {
    prevent_destroy = false
  }
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
  count      = var.archived ? 0 : 1
  repository = github_repository.this.name
  branch     = var.default_branch
}

resource "github_branch_protection" "this" {
  count                           = var.archived ? 0 : 1
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
