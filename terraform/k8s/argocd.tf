data "terraform_remote_state" "github" {
  backend = "remote"

  config = {
    organization = "mazino2d-everything-as-code"
    workspaces = {
      name = "github"
    }
  }
}

locals {
  argocd_apps = {
    infra      = "kubernetes/clusters/mazino2d-as-se1-dev/infra"
    monitoring = "kubernetes/clusters/mazino2d-as-se1-dev/monitoring"
    apps       = "kubernetes/clusters/mazino2d-as-se1-dev/apps"
  }
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "9.5.9"
  namespace        = "argocd"
  create_namespace = true
  values = [<<-YAML
    configs:
      cm:
        kustomize.buildOptions: "--enable-helm"
    server:
      certificate:
        enabled: true
        domain: argocd.mazino2d-k3s.duckdns.org
        issuer:
          group: cert-manager.io
          kind: ClusterIssuer
          name: letsencrypt-staging
      ingress:
        enabled: true
        ingressClassName: traefik
        hostname: argocd.mazino2d-k3s.duckdns.org
        tls: true
  YAML
  ]
}

resource "kubectl_manifest" "argocd_application" {
  for_each = local.argocd_apps

  yaml_body = <<-YAML
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: ${each.key}
      namespace: argocd
      finalizers:
        - resources-finalizer.argocd.argoproj.io
    spec:
      project: default
      source:
        repoURL: git@github.com:mazino2d/everything-as-code.git
        targetRevision: main
        path: ${each.value}
      destination:
        server: https://kubernetes.default.svc
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
          - ServerSideApply=true
  YAML

  depends_on = [helm_release.argocd]
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
    sshPrivateKey = data.terraform_remote_state.github.outputs.argocd_private_key_pem
  }

  depends_on = [helm_release.argocd]
}
