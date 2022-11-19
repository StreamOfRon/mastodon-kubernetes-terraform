/*

This is provided for example purposes ONLY.  Please see the README file for more information


locals {
  minio_disk_size = "100Gi"
}

resource "kubernetes_stateful_set" "minio" {
  metadata {
    name      = "minio"
    namespace = kubernetes_namespace.kube-namespace.metadata[0].name
    labels = {
      app = "minio"
    }
    annotations = {
      "keel.sh/policy"       = "force"
      "keel.sh/trigger"      = "poll"
      "keel.sh/pollSchedule" = "@daily"
    }
  }

  spec {
    service_name = "minio"
    replicas = 1
    selector {
      match_labels = {
        app = "minio"
      }
    }
    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = {
          app = "minio"
        }
      }
      spec {
        container {
          image             = "quay.io/minio/minio"
          image_pull_policy = "Always"
          name              = "minio"
          args = [
            "server",
            "/data",
            "--console-address",
            ":9001"
          ]
          env_from {
            secret_ref {
              name = "minio-default-creds"
            }
          }
          volume_mount {
            name       = "minio-storage"
            mount_path = "/data"
          }
          liveness_probe {
            http_get {
              path = "/minio/health/live"
              port = 9000
            }
            initial_delay_seconds = 120
            period_seconds        = 20
          }
          readiness_probe {
            http_get {
              path = "/minio/health/ready"
              port = 9000
            }
            initial_delay_seconds = 120
            period_seconds        = 20
          }
        }
      }
      volume_claim_template {
        metadata {
          name = "minio-storage"
        }
        spec {
          access_modes = ["ReadWriteOnce"]
          resources {
            requests = {
              storage = local.minio_disk_size
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "blob-storage" {
  metadata {
    name      = "blob-storage"
    namespace = kubernetes_namespace.kube-namespace.metadata[0].name
  }
  spec {
    selector = {
      app = "minio"
    }
    session_affinity = "ClientIP"
    port {
      port        = 9000
      target_port = 9000
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_ingress_v1" "blob-storage" {
  metadata {
    name      = "blob-storage-ingress"
    namespace = kubernetes_namespace.kube-namespace.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"                      = "traefik"
      "traefik.ingress.kubernetes.io/router.tls"         = "true"
      "traefik.ingress.kubernetes.io/router.entrypoints" = "websecure"
    }
  }
  spec {
    default_backend {
      service {
        name = "blob-storage"
        port {
          number = 9000
        }
      }
    }

    rule {
      host = "blobstore.${var.LOCAL_DOMAIN}"
      http {
        path {
          backend {
            service {
              name = "blob-storage"
              port {
                number = 9000
              }
            }
          }
        }
      }
    }
  }
}

*/
