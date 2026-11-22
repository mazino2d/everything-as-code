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

variable "remote_state_bucket" {
  type        = string
  description = "GCS bucket holding every stack's state under state/<stack path>; remote_state secrets name the stack path."
}
