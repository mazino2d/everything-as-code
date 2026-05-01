locals {
  argocd_apps = {
    infra = {
      path      = "kubernetes/clusters/mazino2d-as-se1-dev/infra"
      sync_wave = 0
      sync_options = [
        "CreateNamespace=true",
        "ServerSideApply=true",
        "ApplyOutOfSyncOnly=true",
        "PruneLast=true",
      ]
    }
    monitoring = {
      path      = "kubernetes/clusters/mazino2d-as-se1-dev/monitoring"
      sync_wave = 1
      sync_options = [
        "CreateNamespace=true",
        "ServerSideApply=true",
        "ApplyOutOfSyncOnly=true",
        "PruneLast=true",
        "SkipDryRunOnMissingResource=true",
      ]
    }
    apps = {
      path      = "kubernetes/clusters/mazino2d-as-se1-dev/apps"
      sync_wave = 2
      sync_options = [
        "CreateNamespace=true",
        "ServerSideApply=true",
        "ApplyOutOfSyncOnly=true",
        "PruneLast=true",
        "SkipDryRunOnMissingResource=true",
      ]
    }
  }
}

data "terraform_remote_state" "github" {
  backend = "remote"

  config = {
    organization = "mazino2d-everything-as-code"
    workspaces = {
      name = "github"
    }
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
      params:
        server.insecure: true
    server:
      ingress:
        enabled: true
        ingressClassName: traefik
        hostname: argocd.mazino2d-k3s.duckdns.org
        tls: false
  YAML
  ]
}

resource "kubectl_manifest" "argocd_application" {
  for_each = local.argocd_apps

  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = each.key
      namespace = "argocd"
      annotations = {
        "argocd.argoproj.io/sync-wave" = tostring(each.value.sync_wave)
      }
      finalizers = [
        "resources-finalizer.argocd.argoproj.io",
      ]
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "git@github.com:mazino2d/everything-as-code.git"
        targetRevision = "main"
        path           = each.value.path
      }
      destination = {
        server = "https://kubernetes.default.svc"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        retry = {
          limit = 20
          backoff = {
            duration    = "15s"
            factor      = 2
            maxDuration = "10m"
          }
        }
        syncOptions = each.value.sync_options
      }
    }
  })

  depends_on = [
    helm_release.argocd,
    kubernetes_secret.argocd_repo_creds,
  ]
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
