variable "name" {
  type        = string
  description = "Display name of the group."
}

variable "org_role" {
  type        = string
  description = "Org-level role for the group: no-access, member, or admin."
  default     = "member"
}

variable "member_usernames" {
  type        = list(string)
  description = "Usernames (email addresses) to add as group members."
  default     = []
}
