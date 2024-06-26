terraform {  
  required_providers {
    argocd = {      
      source = "oboukili/argocd"
      version = "6.1.1"
    }
  }
}

provider "argocd" {
  server_addr = "argocd.practice-zzingo.net:443"
  username    = "admin"
  password    = var.argocd_password
}

################################################################################
# Argo Application
################################################################################

resource "argocd_application" "app" {  
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
