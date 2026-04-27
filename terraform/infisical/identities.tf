module "github_actions" {
  source = "./_modules/infisical-identity"
  name   = "github-actions"
  role   = "no-access"
}

module "cicd" {
  source = "./_modules/infisical-identity"
  name   = "cicd"
  role   = "no-access"

  client_secrets = [
    { name = "grafana", description = "Used by terraform/grafana to store stack credentials into Infisical" },
  ]
}

module "k8s_operator" {
  source = "./_modules/infisical-identity"
  name   = "k8s-operator"
  role   = "no-access"

  client_secrets = [
    { name = "bootstrap", description = "Infisical Kubernetes Operator bootstrap credential" },
  ]
}
