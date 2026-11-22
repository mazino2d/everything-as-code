data "terraform_remote_state" "infisical" {
  backend = "gcs"


  config = {
    bucket = "mazino2d-as-se1-dev-tfstate"
    prefix = "state/infisical"
  }
}

resource "kubernetes_namespace" "infisical_operator" {
  metadata {
    name = "infisical-operator"
  }
}

resource "kubernetes_secret" "infisical_machine_identity" {
  metadata {
    name      = "infisical-machine-identity"
    namespace = "infisical-operator"
  }

  data = {
    clientId     = data.terraform_remote_state.infisical.outputs.k8s_operator_client_id
    clientSecret = data.terraform_remote_state.infisical.outputs.k8s_operator_client_secret
  }

  depends_on = [kubernetes_namespace.infisical_operator]
}
