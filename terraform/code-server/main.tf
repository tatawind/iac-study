terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.20.0"
    }
  }
}

data "kubernetes_namespace" "cloud-workspace" {
  metadata {
    name = "cloud-workspace"
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_persistent_volume" "cws-code-pvc" {
  metadata {
    name = "cws-code-pvc"
  }
  spec {
    capacity = {
      storage = "1Gi"
    }
    access_modes = ["ReadWriteMany"]
    persistent_volume_source {
      requests = {
        storage = "1Gi"
      }
    }
    storage_class_name = "cloud-workspace-ceph"
  }
}

resource "kubernetes_deployment" "cws-codeserver" {
  metadata {
    name = var.user_app_info.app_name
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
          name  = concat("container-" , var.user_app_info.app_name)

          resources {
            limits = {
              cpu    = "2"
              memory = "4Gi"
            }
            requests = {
              cpu    = "1"
              memory = "1Gi"
            }
          }

          env {
            name = "PASSWORD"
            value = "myadmin@#123"
          }
          
          port {
            container_port = 8080
          }

          volume_mount {
            name = var.user_app_info.app_name
            mount_path = "/home/coder/project"
          }
        }
        volume {
          name = var.user_app_info.app_name
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume.cws-code-pvc.name
            read_only = false
          }          
        }
      }
      
    }
  }
}

resource "kubernetes_service" "cws-codeserver-service" {
  metadata {
    name = concat("service-", var.user_app_info.app_name)
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
