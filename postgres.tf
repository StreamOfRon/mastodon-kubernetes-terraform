/*

See README file before proceeding

locals {
  postgres_disk_size = "20Gi"
}

resource "kubernetes_stateful_set" "postgres-db-14" {
  metadata {
    name      = "postgres-db-14"
    namespace = kubernetes_namespace.kube-namespace.metadata[0].name
    labels = {
      app = "postgres-db-14"
    }
    annotations = {
      "keel.sh/policy"       = "force"
      "keel.sh/trigger"      = "poll"
      "keel.sh/pollSchedule" = "@daily"
    }
  }

  spec {
    service_name = "postgres-db-14"
    replicas = 1
    selector {
      match_labels = {
        app = "postgres-db-14"
      }
    }
    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = {
          app = "postgres-db-14"
        }
      }
      spec {
        container {
          image             = "postgres:14"
          image_pull_policy = "Always"
          name              = "postgres-db-14"

          env_from {
            secret_ref {
              name = "postgres-db-14"
            }
          }
          volume_mount {
            name       = "postgres-storage"
            mount_path = "/var/lib/postgresql/data"
          }
          liveness_probe {
            exec {
              command = [
                "pg_isready",
                "-U",
                "postgres"
              ]
            }
            initial_delay_seconds = 120
            period_seconds        = 20
          }
        }
      }
      volume_claim_template {
        metadata {
          name = "postgres-storage"
        }
        spec {
          access_modes = ["ReadWriteOnce"]
          resources {
            requests = {
              storage = local.postgres_disk_size
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "postgres-db" {
  metadata {
    name      = "postgres-db"
    namespace = kubernetes_namespace.kube-namespace.metadata[0].name
  }
  spec {
    selector = {
      app = "postgres-db-14"
    }
    session_affinity = "ClientIP"
    port {
      port        = 5432
      target_port = 5432
    }

    type = "ClusterIP"
  }
}

*/
