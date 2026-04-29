resource "tls_private_key" "argocd" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

output "argocd_public_key" {
  value = tls_private_key.argocd.public_key_openssh
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "7.7.5"
  namespace        = "argocd"
  create_namespace = true
  values           = [file("${path.module}/argocd-values.yaml")]
}

resource "kubernetes_secret" "argocd_repo_creds" {
  metadata {
    name      = "argocd-repo-creds-github"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" = "repo-creds"
    }
  }

  data = {
    type          = "git"
    url           = "git@github.com:mazino2d"
    sshPrivateKey = tls_private_key.argocd.private_key_pem
  }

  depends_on = [helm_release.argocd]
}
