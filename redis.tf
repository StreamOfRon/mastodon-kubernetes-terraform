locals {
  redis_disk_size = "2Gi"
}

resource "kubernetes_stateful_set" "redis-7" {
  metadata {
    name      = "redis-7"
    namespace = var.namespace
    labels = {
      app = "redis-7"
    }
    annotations = {
      "keel.sh/policy"       = "force"
      "keel.sh/trigger"      = "poll"
      "keel.sh/pollSchedule" = "@daily"
    }
  }

  spec {
    service_name = "redis-7"
    replicas = 1
    selector {
      match_labels = {
        app = "redis-7"
      }
    }

    template {
      metadata {
        labels = {
          app = "redis-7"
        }
      }
      spec {
        container {
          image             = "redis:7-alpine"
          image_pull_policy = "Always"
          name              = "redis-7"

          volume_mount {
            name       = "redis-storage"
            mount_path = "/data"
          }
          liveness_probe {
            exec {
              command = [
                "redis-cli",
                "ping"
              ]
            }
            initial_delay_seconds = 30
            period_seconds        = 20
          }
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "redis-storage"
      }
      spec {
        access_modes = ["ReadWriteOnce"]
        resources {
          requests = {
            storage = local.redis_disk_size
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "redis" {
  metadata {
    name      = "redis"
    namespace = var.namespace
  }
  spec {
    selector = {
      app = "redis-7"
    }
    session_affinity = "ClientIP"
    port {
      port        = 6379
      target_port = 6379
    }

    type = "ClusterIP"
  }
}
