variable "kube_host" {
  type = string
  description = "Kubernetes endpoint"
}

variable "kube_token" {
  type = string
  sensitive = true
  description = "Service account auth token used to manage deployments"
}

variable "kube_insecure" {
  type = bool
  description = "Set to true or modify providers.tf to pass cluster_ca_certificate if your kubernetes endpoint uses a self-signed TLS certificate"
}

variable "namespace" {
  type        = string
  default     = "default"
  description = "Kubernetes namespace to deploy into"
}

variable "nameservers" {
  description = "A list of nameservers to configure in the pods"
  default = []
}

variable "AWS_ACCESS_KEY_ID" {
  type      = string
  sensitive = true
}

variable "AWS_SECRET_ACCESS_KEY" {
  type      = string
  sensitive = true
}

variable "CACHE_REDIS_PORT" {
  type    = string
  default = "6379"
}

variable "DATABASE_URL" {
  type      = string
  sensitive = true
}

variable "ES_ENABLED" {
  type    = string
  default = "false"
}

variable "ES_HOST" {
  type      = string
  sensitive = true
  default   = ""
}

variable "IP_RETENTION_PERIOD" {
  type    = string
  default = "31556952"
}

variable "LOCAL_DOMAIN" {
  type = string
}

variable "OTP_SECRET" {
  type      = string
  sensitive = true
}

variable "REDIS_HOST" {
  type      = string
  sensitive = true
}

variable "REDIS_PORT" {
  type    = string
  default = "6379"
}

variable "S3_ALIAS_HOST" {
  type      = string
  sensitive = true
}

variable "S3_BUCKET" {
  type      = string
  sensitive = true
}

variable "S3_ENABLED" {
  type    = string
  default = "true"
}

variable "S3_ENDPOINT" {
  type      = string
  sensitive = true
}

variable "S3_HOSTNAME" {
  type      = string
  sensitive = true
}

variable "SECRET_KEY_BASE" {
  type      = string
  sensitive = true
}

variable "SESSION_RETENTION_PERIOD" {
  type    = string
  default = "31556952"
}

variable "SMTP_FROM_ADDRESS" {
  type      = string
  sensitive = true
}

variable "SMTP_PORT" {
  type    = string
  default = "25"
}

variable "SMTP_SERVER" {
  type      = string
  sensitive = true
}

variable "SMTP_LOGIN" {
  type      = string
  sensitive = true
  default = ""
}

variable "SMTP_PASSWORD" {
  type      = string
  sensitive = true
  default = ""
}

variable "TRUSTED_PROXY_IP" {
  type      = string
  sensitive = true
}

variable "VAPID_PRIVATE_KEY" {
  type      = string
  sensitive = true
}

variable "VAPID_PUBLIC_KEY" {
  type      = string
  sensitive = true
}
