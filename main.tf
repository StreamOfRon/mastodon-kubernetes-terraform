locals {
  mastodon_image_identifier       = "tootsuite/mastodon:v4.1.4"
  nginx_instance_count            = 1
  web_instance_count              = 1
  streaming_instance_count        = 1
  web_puma_processes_per_instance = 2
  threads_per_puma_process        = 8
  use_prepared_statements         = true
  user_active_days                = 7

  # Change this if you are using connection pooling - this will be used by database migrations, which do not behave correctly with pooling
  nonpooled_database_url          = var.DATABASE_URL

  sidekiq_default_replicas = 1
  sidekiq_default_threads  = 2
  sidekiq_ingress_replicas = 1
  sidekiq_ingress_threads  = 2
  sidekiq_mailers_replicas = 1
  sidekiq_mailers_threads  = 2
  sidekiq_pull_replicas    = 1
  sidekiq_pull_threads     = 8
  sidekiq_push_replicas    = 1
  sidekiq_push_threads     = 2
  # Only one scheduler replica can be run
  sidekiq_scheduler_threads = 2
}


resource "kubernetes_namespace" "kube-namespace" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_job" "mastodon-db-setup" {
    metadata {
        name = "mastodon-db-setup"
        namespace = kubernetes_namespace.kube-namespace.metadata[0].name
    }
    spec {
        template {
            metadata {}
            spec {
                container {
                    image = local.mastodon_image_identifier
                    image_pull_policy = "IfNotPresent"
                    name = "mastodon-db-migrate"
                    command = ["bundle"]
                    args = [
                        "exec",
                        "rake",
                        "db:setup"
                    ]
                    env_from {
                        secret_ref {
                            name = kubernetes_secret.mastodon-secrets.metadata[0].name
                        }
                    }
                    env {
                      name = "DATABASE_URL"
                      value = local.nonpooled_database_url
                    }
                }
            }
        }
    }
}

resource "kubernetes_service" "mastodon-nginx" {
  metadata {
    name      = "mastodon-nginx"
    namespace = kubernetes_namespace.kube-namespace.metadata[0].name
  }
  spec {
    selector = {
      app = "mastodon-nginx"
    }
    session_affinity = "ClientIP"
    port {
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_service" "mastodon-web" {
  metadata {
    name      = "mastodon-web"
    namespace = kubernetes_namespace.kube-namespace.metadata[0].name
  }
  spec {
    selector = {
      app = "mastodon-web"
    }
    session_affinity = "ClientIP"
    port {
      port        = 3000
      target_port = 3000
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_service" "mastodon-streaming" {
  metadata {
    name      = "mastodon-streaming"
    namespace = kubernetes_namespace.kube-namespace.metadata[0].name
  }
  spec {
    selector = {
      app = "mastodon-streaming"
    }
    session_affinity = "ClientIP"
    port {
      port        = 4000
      target_port = 4000
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_config_map" "mastodon-nginx" {
  metadata {
    name      = "mastodon-nginx"
    namespace = kubernetes_namespace.kube-namespace.metadata[0].name
  }
  data = {
    "mastodon.conf" = "${file("${path.module}/resources/nginx/mastodon.conf")}"
  }
}

resource "kubernetes_config_map" "mastodon-config" {
  metadata {
    name      = "mastodon-env"
    namespace = kubernetes_namespace.kube-namespace.metadata[0].name
  }

  data = {
    "WEB_CONCURRENCY"     = local.web_puma_processes_per_instance
    "MAX_THREADS"         = local.threads_per_puma_process
    "PREPARED_STATEMENTS" = local.use_prepared_statements
    "USER_ACTIVE_DAYS"    = local.user_active_days
  }
}

resource "kubernetes_secret" "mastodon-secrets" {
  metadata {
    name      = "mastodon-env"
    namespace = kubernetes_namespace.kube-namespace.metadata[0].name
  }

  data = {
    AWS_ACCESS_KEY_ID        = var.AWS_ACCESS_KEY_ID
    AWS_SECRET_ACCESS_KEY    = var.AWS_SECRET_ACCESS_KEY
    CACHE_REDIS_PORT         = var.CACHE_REDIS_PORT
    DATABASE_URL             = var.DATABASE_URL
    ES_ENABLED               = var.ES_ENABLED
    ES_HOST                  = var.ES_HOST
    IP_RETENTION_PERIOD      = var.IP_RETENTION_PERIOD
    LOCAL_DOMAIN             = var.LOCAL_DOMAIN
    OTP_SECRET               = var.OTP_SECRET
    REDIS_HOST               = var.REDIS_HOST
    REDIS_PORT               = var.REDIS_PORT
    S3_ALIAS_HOST            = var.S3_ALIAS_HOST
    S3_BUCKET                = var.S3_BUCKET
    S3_ENABLED               = var.S3_ENABLED
    S3_ENDPOINT              = var.S3_ENDPOINT
    S3_HOSTNAME              = var.S3_HOSTNAME
    SECRET_KEY_BASE          = var.SECRET_KEY_BASE
    SESSION_RETENTION_PERIOD = var.SESSION_RETENTION_PERIOD
    SMTP_FROM_ADDRESS        = var.SMTP_FROM_ADDRESS
    SMTP_PORT                = var.SMTP_PORT
    SMTP_SERVER              = var.SMTP_SERVER
    SMTP_LOGIN               = var.SMTP_LOGIN
    SMTP_PASSWORD            = var.SMTP_PASSWORD
    TRUSTED_PROXY_IP         = var.TRUSTED_PROXY_IP
    VAPID_PRIVATE_KEY        = var.VAPID_PRIVATE_KEY
    VAPID_PUBLIC_KEY         = var.VAPID_PUBLIC_KEY
  }
}

resource "kubernetes_stateful_set" "mastodon-nginx" {
  metadata {
    name      = "mastodon-nginx"
    namespace = kubernetes_namespace.kube-namespace.metadata[0].name
    labels = {
      app = "mastodon-nginx"
    }
    annotations = {
      "keel.sh/policy"       = "force"
      "keel.sh/trigger"      = "poll"
      "keel.sh/pollSchedule" = "@daily"
    }
  }

  spec {
    replicas = local.nginx_instance_count
    selector {
      match_labels = {
        app = "mastodon-nginx"
      }
    }
    service_name = "mastodon-nginx"

    template {
      metadata {
        labels = {
          app = "mastodon-nginx"
        }
      }
      spec {

        init_container {
          security_context {
            run_as_user = 0
            run_as_group = 0
          }
          image = local.mastodon_image_identifier
          image_pull_policy = "IfNotPresent"
          name = "copy-public-files"
          command = ["bash"]
          args = [
              "-c",
              "rm -rf /var/www/html/* ; cp -Rp /mastodon/public/* /var/www/html/"
          ]
          volume_mount {
            name = "nginx-storage"
            mount_path = "/var/www/html"
          }
        }
        container {
          name  = "nginx"
          image = "nginx:alpine"
          volume_mount {
            name       = "nginx"
            mount_path = "/etc/nginx/conf.d"
            read_only  = true
          }
          volume_mount {
            name = "nginx-storage"
            mount_path = "/var/www/html"
          }
          liveness_probe {
            http_get {
              path = "/health"
              port = 80
            }
            initial_delay_seconds = 20
            period_seconds        = 20
          }
        }
        volume {
          name = "nginx"
          config_map {
            name = kubernetes_config_map.mastodon-nginx.metadata[0].name
          }
        }

      }
    }
    volume_claim_template {
      metadata {
        name = "nginx-storage"
      }
      spec {
        access_modes = ["ReadWriteOnce"]
        resources {
          requests = {
            storage = "1Gi"
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "mastodon-web" {
  metadata {
    name      = "mastodon-web"
    namespace = kubernetes_namespace.kube-namespace.metadata[0].name
    labels = {
      app = "mastodon-web"
    }
    annotations = {
      "keel.sh/policy"       = "force"
      "keel.sh/trigger"      = "poll"
      "keel.sh/pollSchedule" = "@daily"
    }
  }

  spec {
    replicas = local.web_instance_count
    selector {
      match_labels = {
        app = "mastodon-web"
      }
    }
    strategy {
      type = "RollingUpdate"
    }

    template {
      metadata {
        labels = {
          app = "mastodon-web"
        }
      }
      spec {
        init_container {
          image             = local.mastodon_image_identifier
          image_pull_policy = "IfNotPresent"
          name              = "mastodon-db-migrate"
          command           = ["bundle"]
          args = [
            "exec",
            "rake",
            "db:migrate"
          ]
          env_from {
            secret_ref {
              name = kubernetes_secret.mastodon-secrets.metadata[0].name
            }
          }
          env {
            name  = "SKIP_POST_DEPLOYMENT_MIGRATIONS"
            value = "true"
          }
          env {
            name = "DATABASE_URL"
            value = local.nonpooled_database_url
          }
        }
        container {
          image             = local.mastodon_image_identifier
          image_pull_policy = "IfNotPresent"
          name              = "mastodon-web"
          command           = ["bash"]
          args = [
            "-c",
            "rm -f /mastodon/tmp/pids/server.pid; bundle exec rails s -p 3000"
          ]
          env_from {
            secret_ref {
              name = kubernetes_secret.mastodon-secrets.metadata[0].name
            }
          }
          env_from {
            config_map_ref {
              name = kubernetes_config_map.mastodon-config.metadata[0].name
            }
          }
          liveness_probe {
            http_get {
              path = "/health"
              port = 3000
            }
            initial_delay_seconds = 60
            period_seconds        = 20
          }
        }
        dns_config {
          nameservers = var.nameservers
          option {
            name  = "ndots"
            value = 1
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "mastodon-streaming" {
  metadata {
    name      = "mastodon-streaming"
    namespace = kubernetes_namespace.kube-namespace.metadata[0].name
    labels = {
      app = "mastodon-streaming"
    }
    annotations = {
      "keel.sh/policy"       = "force"
      "keel.sh/trigger"      = "poll"
      "keel.sh/pollSchedule" = "@daily"
    }
  }

  spec {
    replicas = local.streaming_instance_count
    selector {
      match_labels = {
        app = "mastodon-streaming"
      }
    }
    strategy {
      type = "RollingUpdate"
    }

    template {
      metadata {
        labels = {
          app = "mastodon-streaming"
        }
      }
      spec {
        container {
          image             = local.mastodon_image_identifier
          image_pull_policy = "IfNotPresent"
          name              = "mastodon-streaming"
          command           = ["bash"]
          args = [
            "-c",
            "node ./streaming"
          ]
          env_from {
            secret_ref {
              name = kubernetes_secret.mastodon-secrets.metadata[0].name
            }
          }
          env_from {
            config_map_ref {
              name = kubernetes_config_map.mastodon-config.metadata[0].name
            }
          }
          liveness_probe {
            http_get {
              path = "/api/v1/streaming/health"
              port = 4000
            }
            initial_delay_seconds = 60
            period_seconds        = 20
          }
        }
        dns_config {
          nameservers = var.nameservers
          option {
            name  = "ndots"
            value = 1
          }
        }
      }
    }
  }
}

resource "kubernetes_cron_job_v1" "media-cleanup" {
  metadata {
    name      = "mastodon-media-cleanup"
    namespace = kubernetes_namespace.kube-namespace.metadata[0].name
  }
  spec {
    concurrency_policy = "Forbid"
    schedule           = "30 */4 * * *"
    job_template {
      metadata {}
      spec {
        template {
          metadata {}
          spec {
            container {
              name    = "mastodon-media-cleanup"
              image   = local.mastodon_image_identifier
              command = ["bash", "-c", "tootctl media remove"]
              env_from {
                secret_ref {
                  name = kubernetes_secret.mastodon-secrets.metadata[0].name
                }
              }
              env_from {
                config_map_ref {
                  name = kubernetes_config_map.mastodon-config.metadata[0].name
                }
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_cron_job_v1" "preview-cleanup" {
  metadata {
    name      = "mastodon-preview-cleanup"
    namespace = kubernetes_namespace.kube-namespace.metadata[0].name
  }
  spec {
    concurrency_policy = "Forbid"
    schedule           = "30 */4 * * *"
    job_template {
      metadata {}
      spec {
        template {
          metadata {}
          spec {
            container {
              name    = "mastodon-preview-cleanup"
              image   = local.mastodon_image_identifier
              command = ["bash", "-c", "tootctl preview_cards remove"]
              env_from {
                secret_ref {
                  name = kubernetes_secret.mastodon-secrets.metadata[0].name
                }
              }
              env_from {
                config_map_ref {
                  name = kubernetes_config_map.mastodon-config.metadata[0].name
                }
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_ingress_v1" "mastodon-nginx" {
  metadata {
    name      = "mastodon-nginx-ingress"
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
        name = "mastodon-nginx"
        port {
          number = 80
        }
      }
    }

    rule {
      host = var.LOCAL_DOMAIN
      http {
        path {
          backend {
            service {
              name = "mastodon-nginx"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
    rule {
      host = "www.${var.LOCAL_DOMAIN}"
      http {
        path {
          backend {
            service {
              name = "mastodon-nginx"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}