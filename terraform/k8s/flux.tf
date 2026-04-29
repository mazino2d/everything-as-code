resource "tls_private_key" "flux" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "helm_release" "flux" {
  name             = "flux2"
  repository       = "https://fluxcd-community.github.io/helm-charts"
  chart            = "flux2"
  version          = "2.13.0"
  namespace        = "flux-system"
  create_namespace = true
}

resource "kubernetes_secret" "flux_system" {
  metadata {
    name      = "flux-system"
    namespace = "flux-system"
  }

  depends_on = [helm_release.flux]

  data = {
    identity       = tls_private_key.flux.private_key_openssh
    "identity.pub" = tls_private_key.flux.public_key_openssh
    known_hosts    = "github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg="
  }
}

output "flux_public_key" {
  value = tls_private_key.flux.public_key_openssh
}

resource "kubernetes_manifest" "flux_git_repository" {
  manifest = {
    apiVersion = "source.toolkit.fluxcd.io/v1"
    kind       = "GitRepository"
    metadata = {
      name      = "flux-system"
      namespace = "flux-system"
    }
    spec = {
      interval  = "1m"
      url       = "ssh://git@github.com/mazino2d/everything-as-code"
      ref       = { branch = "main" }
      secretRef = { name = "flux-system" }
    }
  }

  depends_on = [kubernetes_secret.flux_system]
}

resource "kubernetes_manifest" "flux_kustomization" {
  manifest = {
    apiVersion = "kustomize.toolkit.fluxcd.io/v1"
    kind       = "Kustomization"
    metadata = {
      name      = "flux-system"
      namespace = "flux-system"
    }
    spec = {
      interval  = "1m"
      path      = "./kubernetes/clusters/mazino2d-as-se1-dev/flux-system"
      prune     = true
      sourceRef = { kind = "GitRepository", name = "flux-system" }
    }
  }

  depends_on = [kubernetes_manifest.flux_git_repository]
}
