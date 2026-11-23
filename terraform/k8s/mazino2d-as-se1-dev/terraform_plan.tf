# Pull request plans run as the read-only terraform-plan@mazino2d-as-se1-dev, whose project
# roles (terraform/gcp/mazino2d-as-se1-dev/terraform_wif.tf) cannot read
# Secrets. Plans refresh this stack's Secrets and Helm releases (stored as
# Secrets), so this read-only role covers every resource, Secrets included.
resource "kubernetes_cluster_role" "terraform_plan" {
  metadata {
    name = "terraform-plan"
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "terraform_plan" {
  metadata {
    name = "terraform-plan"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.terraform_plan.metadata[0].name
  }

  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "User"
    name      = "terraform-plan@mazino2d-as-se1-dev.iam.gserviceaccount.com"
  }
}
