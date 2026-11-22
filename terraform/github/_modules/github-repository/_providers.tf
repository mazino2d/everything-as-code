# Without this, the module would get an unconfigured hashicorp/github provider
# instead of the root's integrations/github one (token and owner).
terraform {
  required_providers {
    github = {
      source = "integrations/github"
    }
  }
}
