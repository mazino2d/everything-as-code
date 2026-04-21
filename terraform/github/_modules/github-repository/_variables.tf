variable "name" {
  type = string
}

variable "description" {
  type    = string
  default = ""
}

variable "visibility" {
  type    = string
  default = "public"
}

variable "topics" {
  type    = list(string)
  default = []
}

variable "has_issues" {
  type    = bool
  default = true
}

variable "has_wiki" {
  type    = bool
  default = true
}

variable "has_projects" {
  type    = bool
  default = true
}

variable "has_discussions" {
  type    = bool
  default = false
}

variable "allow_merge_commit" {
  type    = bool
  default = false
}

variable "allow_squash_merge" {
  type    = bool
  default = true
}

variable "allow_rebase_merge" {
  type    = bool
  default = false
}

variable "allow_auto_merge" {
  type    = bool
  default = null
}

variable "is_template" {
  type    = bool
  default = false
}

variable "pages" {
  type = object({
    branch     = optional(string, null)
    path       = optional(string, "/")
    cname      = optional(string, null)
    build_type = optional(string, "legacy")
  })
  default = null
}


variable "delete_branch_on_merge" {
  type    = bool
  default = true
}

variable "default_branch" {
  type    = string
  default = "main"
}

variable "archived" {
  type    = bool
  default = false
}

variable "branch_protection" {
  type = object({
    required_approving_review_count = optional(number, 0)
    require_conversation_resolution = optional(bool, false)
    enforce_admins                  = optional(bool, true)
    dismiss_stale_reviews           = optional(bool, true)
    required_linear_history         = optional(bool, true)
    required_status_checks = optional(object({
      strict   = optional(bool, true)
      contexts = optional(list(string), [])
    }), null)
  })
  default = {}
}
