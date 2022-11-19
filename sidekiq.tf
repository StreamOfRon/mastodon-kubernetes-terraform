resource "kubernetes_deployment" "mastodon-sidekiq-default" {
  metadata {
    name      = "mastodon-sidekiq-default"
    namespace = kubernetes_namespace.kube-namespace.metadata[0].name
    labels = {
      app = "mastodon-sidekiq-default"
    }
    annotations = {
      "keel.sh/policy"       = "force"
      "keel.sh/trigger"      = "poll"
      "keel.sh/pollSchedule" = "@daily"
    }
  }

  spec {
    replicas = local.sidekiq_default_replicas
    selector {
      match_labels = {
        app = "mastodon-sidekiq-default"
      }
    }
    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = {
          app = "mastodon-sidekiq-default"
        }
      }
      spec {
        container {
          image             = local.mastodon_image_identifier
          image_pull_policy = "IfNotPresent"
          name              = "mastodon-sidekiq-default"
          command           = ["bash"]
          args = [
            "-c",
            "bundle exec sidekiq -q default -c ${local.sidekiq_default_threads}"
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

resource "kubernetes_deployment" "mastodon-sidekiq-ingress" {
  metadata {
    name      = "mastodon-sidekiq-ingress"
    namespace = kubernetes_namespace.kube-namespace.metadata[0].name
    labels = {
      app = "mastodon-sidekiq-ingress"
    }
    annotations = {
      "keel.sh/policy"       = "force"
      "keel.sh/trigger"      = "poll"
      "keel.sh/pollSchedule" = "@daily"
    }
  }

  spec {
    replicas = local.sidekiq_ingress_replicas
    selector {
      match_labels = {
        app = "mastodon-sidekiq-ingress"
      }
    }
    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = {
          app = "mastodon-sidekiq-ingress"
        }
      }
      spec {
        container {
          image             = local.mastodon_image_identifier
          image_pull_policy = "IfNotPresent"
          name              = "mastodon-sidekiq-ingress"
          command           = ["bash"]
          args = [
            "-c",
            "bundle exec sidekiq -q ingress -c ${local.sidekiq_ingress_threads}"
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

resource "kubernetes_deployment" "mastodon-sidekiq-mailers" {
  metadata {
    name      = "mastodon-sidekiq-mailers"
    namespace = kubernetes_namespace.kube-namespace.metadata[0].name
    labels = {
      app = "mastodon-sidekiq-mailers"
    }
    annotations = {
      "keel.sh/policy"       = "force"
      "keel.sh/trigger"      = "poll"
      "keel.sh/pollSchedule" = "@daily"
    }
  }

  spec {
    replicas = local.sidekiq_mailers_replicas
    selector {
      match_labels = {
        app = "mastodon-sidekiq-mailers"
      }
    }
    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = {
          app = "mastodon-sidekiq-mailers"
        }
      }
      spec {
        container {
          image             = local.mastodon_image_identifier
          image_pull_policy = "IfNotPresent"
          name              = "mastodon-sidekiq-mailers"
          command           = ["bash"]
          args = [
            "-c",
            "bundle exec sidekiq -q mailers -c ${local.sidekiq_mailers_threads}"
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

resource "kubernetes_deployment" "mastodon-sidekiq-pull" {
  metadata {
    name      = "mastodon-sidekiq-pull"
    namespace = kubernetes_namespace.kube-namespace.metadata[0].name
    labels = {
      app = "mastodon-sidekiq-pull"
    }
    annotations = {
      "keel.sh/policy"       = "force"
      "keel.sh/trigger"      = "poll"
      "keel.sh/pollSchedule" = "@daily"
    }
  }

  spec {
    replicas = local.sidekiq_pull_replicas
    selector {
      match_labels = {
        app = "mastodon-sidekiq-pull"
      }
    }
    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = {
          app = "mastodon-sidekiq-pull"
        }
      }
      spec {
        container {
          image             = local.mastodon_image_identifier
          image_pull_policy = "IfNotPresent"
          name              = "mastodon-sidekiq-pull"
          command           = ["bash"]
          args = [
            "-c",
            "bundle exec sidekiq -q pull -c ${local.sidekiq_pull_threads}"
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

resource "kubernetes_deployment" "mastodon-sidekiq-push" {
  metadata {
    name      = "mastodon-sidekiq-push"
    namespace = kubernetes_namespace.kube-namespace.metadata[0].name
    labels = {
      app = "mastodon-sidekiq-push"
    }
    annotations = {
      "keel.sh/policy"       = "force"
      "keel.sh/trigger"      = "poll"
      "keel.sh/pollSchedule" = "@daily"
    }
  }

  spec {
    replicas = local.sidekiq_push_replicas
    selector {
      match_labels = {
        app = "mastodon-sidekiq-push"
      }
    }
    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = {
          app = "mastodon-sidekiq-push"
        }
      }
      spec {
        container {
          image             = local.mastodon_image_identifier
          image_pull_policy = "IfNotPresent"
          name              = "mastodon-sidekiq-push"
          command           = ["bash"]
          args = [
            "-c",
            "bundle exec sidekiq -q push -c ${local.sidekiq_push_threads}"
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

resource "kubernetes_deployment" "mastodon-sidekiq-scheduler" {
  metadata {
    name      = "mastodon-sidekiq-scheduler"
    namespace = kubernetes_namespace.kube-namespace.metadata[0].name
    labels = {
      app = "mastodon-sidekiq-scheduler"
    }
    annotations = {
      "keel.sh/policy"       = "force"
      "keel.sh/trigger"      = "poll"
      "keel.sh/pollSchedule" = "@daily"
    }
  }

  spec {
    # per the docs on scalability, this worker cannot safely run multiple instances
    replicas = 1
    selector {
      match_labels = {
        app = "mastodon-sidekiq-scheduler"
      }
    }
    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = {
          app = "mastodon-sidekiq-scheduler"
        }
      }
      spec {
        container {
          image             = local.mastodon_image_identifier
          image_pull_policy = "IfNotPresent"
          name              = "mastodon-sidekiq-scheduler"
          command           = ["bash"]
          args = [
            "-c",
            "bundle exec sidekiq -q scheduler -c ${local.sidekiq_scheduler_threads}"
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
