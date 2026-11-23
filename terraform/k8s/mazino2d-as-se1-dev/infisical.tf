resource "kubernetes_namespace" "infisical_operator" {
  metadata {
    name = "infisical-operator"
  }
}

resource "kubernetes_secret" "infisical_machine_identity" {
  metadata {
    name      = "infisical-machine-identity"
    namespace = kubernetes_namespace.infisical_operator.metadata[0].name
  }

  data = {
    clientId     = data.terraform_remote_state.infisical.outputs.k8s_operator_client_id
    clientSecret = data.terraform_remote_state.infisical.outputs.k8s_operator_client_secret
  }
}
