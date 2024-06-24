terraform {  
  required_providers {
    argocd = {
      source = "oboukili/argocd"
      version = "6.1.1"
    }
  }
}

provider "argocd" {
  server_addr = "argocd.practice-zzingo.net"
  username    = "admin"
  password    = "xWm1-b4xQNyXCgdO"
}

################################################################################
# Argo Application
################################################################################

resource "argocd_application" "hori" {
  depends_on = [ module.eks, module.eks_blueprints_addons ]
  metadata {
    name = "hori"
    namespace = "argocd"
    annotations = {
      "argocd-image-updater.argoproj.io/hori-backend.allow-tags"       = "regexp:^\\d{8}-\\d{1,}$"
      "argocd-image-updater.argoproj.io/hori-backend.helm.image-name"  = "backend.image.repository"
      "argocd-image-updater.argoproj.io/hori-backend.helm.image-tag"   = "backend.image.tag"
      "argocd-image-updater.argoproj.io/hori-backend.update-strategy"  = "name"
      "argocd-image-updater.argoproj.io/hori-frontend.allow-tags"      = "regexp:^\\d{8}-\\d{1,}$"
      "argocd-image-updater.argoproj.io/hori-frontend.helm.image-name" = "frontend.image.repository"
      "argocd-image-updater.argoproj.io/hori-frontend.helm.image-tag"  = "frontend.image.tag"
      "argocd-image-updater.argoproj.io/hori-frontend.update-strategy" = "name"
      "argocd-image-updater.argoproj.io/image-list"                    = "hori-frontend=zzingo5/hori-frontend,hori-backend=zzingo5/hori-backend"
    }
  }

  spec {
    project = "default"

    source {
      repo_url         = "https://github.com/zzingobomi/hori-helm-chart"
      target_revision  = "main"
      path             = "eks"
      helm {
        value_files = ["values.yaml"]
      }
    }

    destination {
      server      = "https://kubernetes.default.svc"
      namespace   = "hori"
    }

    sync_policy {
      automated {
        prune       = true
        self_heal   = true
        allow_empty = false
      }
      sync_options = ["CreateNamespace=true"]
    }
  }
}
