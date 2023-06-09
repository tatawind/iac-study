terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.20.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

data "kubernetes_namespace" "cloud-workspace" {
  metadata {
    name = "cloud-workspace"
  }
}

resource "kubernetes_persistent_volume_claim" "cws-code-pvc" {
  metadata {
    name = format("cws-code-pvc-%s", var.user_app_info.user_name)
    namespace = data.kubernetes_namespace.cloud-workspace.metadata[0].name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "1Gi"
      }
      limits = {
        storage = "1Gi"
      }
    }
    storage_class_name = "cloud-workspace-ceph"
  }
}

resource "kubernetes_deployment" "cws-codeserver" {
  metadata {
    name = var.user_app_info.app_name
    namespace = data.kubernetes_namespace.cloud-workspace.metadata[0].name
    labels = {
      app = var.user_app_info.label_app
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = var.user_app_info.label_app
      }
    }

    template {
      metadata {
        labels = {
          app = var.user_app_info.label_app
        }
      }

      spec {        
        container {
          image = "codercom/code-server:latest"
          name  = format("container-%s" , var.user_app_info.app_name)

          resources {
            limits = {
              cpu    = "2"
              memory = "4Gi"
            }
            requests = {
              cpu    = "0.5"
              memory = "1Gi"
            }
          }

          args = [ "--auth", "none" ]
          
          port {
            container_port = 8080
          }

          volume_mount {
            name = var.user_app_info.app_name
            mount_path = "/home/coder/project"
          }
          working_dir = "/home/coder/project"
        }
        security_context {          
          fs_group = 1000
        }
        volume {
          name = var.user_app_info.app_name
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.cws-code-pvc.metadata[0].name
            read_only = false
          }          
        }
      }
      
    }
  }
}

resource "kubernetes_service" "cws-codeserver-service" {
  metadata {
    name = format("service-%s" , var.user_app_info.app_name)
    namespace = data.kubernetes_namespace.cloud-workspace.metadata[0].name
  }
  spec {
    selector = {
      app = var.user_app_info.label_app
    }
    port {
      port        = 8080
      target_port = 8080
    }

    type = "ClusterIP"
  }
}
