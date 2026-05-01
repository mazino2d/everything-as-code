variable "project_id" {
  type        = string
  description = "Infisical project/workspace ID."
}

variable "environments" {
  type        = list(string)
  description = "Infisical environments where folders and secrets are created."
}

variable "tree" {
  type        = any
  description = "Tree config loaded from secret_tree.yaml."
}

variable "remote_state_organization" {
  type        = string
  description = "Terraform Cloud organization used when resolving remote_state secrets."
}
