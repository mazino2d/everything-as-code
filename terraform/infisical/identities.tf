module "k8s_operator" {
  source = "./_modules/infisical-identity"
  name   = "k8s-operator"
  role   = "no-access"

  client_secrets = [
    { name = "bootstrap", description = "Infisical Kubernetes Operator bootstrap credential" },
  ]
}
