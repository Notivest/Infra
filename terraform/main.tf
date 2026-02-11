provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

locals {
  api_domain       = "api.${var.domain_root}"
  frontend_domains = [var.domain_root, "www.${var.domain_root}"]
  all_domains      = concat(local.frontend_domains, [local.api_domain])
  secret_names     = toset(distinct(flatten([for svc in var.services : values(svc.secret_env)])))
  cloudsql_connection_name = try(google_sql_database_instance.primary[0].connection_name, "")
}

resource "google_project_service" "apis" {
  for_each = toset([
    "compute.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "sqladmin.googleapis.com",
    "iam.googleapis.com",
  ])

  service            = each.value
  disable_on_destroy = false
}

resource "google_service_account" "run" {
  account_id   = "notivest-run"
  display_name = "Notivest Cloud Run runtime"
}

resource "google_project_iam_member" "run_roles" {
  for_each = toset([
    "roles/secretmanager.secretAccessor",
    "roles/cloudsql.client",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.run.email}"
}

resource "google_secret_manager_secret" "secrets" {
  for_each = local.secret_names

  secret_id = each.value
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "secrets" {
  for_each = {
    for name in nonsensitive(keys(var.secret_values)) : name => name
    if contains(local.secret_names, name)
  }

  secret      = google_secret_manager_secret.secrets[each.key].id
  secret_data = var.secret_values[each.key]
}

resource "google_sql_database_instance" "primary" {
  count = var.enable_cloud_sql ? 1 : 0

  name             = var.cloudsql_instance_name
  region           = var.region
  database_version = var.cloudsql_version
  deletion_protection = var.cloudsql_deletion_protection

  settings {
    # Keep SQL running by default in pause mode because the provider cannot
    # manage sql users/databases reliably while the instance is stopped.
    activation_policy = (var.pause_mode && var.pause_cloud_sql) ? "NEVER" : "ALWAYS"

    tier = var.cloudsql_tier

    disk_size = var.cloudsql_disk_gb

    backup_configuration {
      enabled = true
    }

    ip_configuration {
      ipv4_enabled = true
    }
  }

  depends_on = [google_project_service.apis]
}

resource "google_sql_database" "databases" {
  for_each = var.enable_cloud_sql ? toset(var.cloudsql_databases) : toset([])

  name     = each.value
  instance = google_sql_database_instance.primary[0].name
}

resource "google_sql_user" "users" {
  for_each = var.enable_cloud_sql ? toset(nonsensitive(keys(var.cloudsql_users))) : toset([])

  name     = each.key
  instance = google_sql_database_instance.primary[0].name
  password = var.cloudsql_users[each.key]
}

resource "google_cloud_run_service" "services" {
  for_each = var.services

  name     = each.key
  location = var.region

  lifecycle {
    ignore_changes = [
      # `gcloud run deploy` adds these annotations; ignoring prevents Terraform from forcing a new revision
      # just to remove them.
      template[0].metadata[0].annotations["run.googleapis.com/client-name"],
      template[0].metadata[0].annotations["run.googleapis.com/client-version"],

      # `gcloud run deploy` often sets this; Terraform doesn't need to manage it.
      template[0].metadata[0].name,
    ]
  }

  metadata {
    annotations = {
      "run.googleapis.com/ingress" = var.pause_mode ? "internal" : "all"
    }
  }

  template {
    metadata {
      annotations = merge(
        {
          "autoscaling.knative.dev/minScale" = tostring(var.pause_mode ? 0 : each.value.min_instances)
          "autoscaling.knative.dev/maxScale" = tostring(each.value.max_instances)
        },
        var.enable_cloud_sql ? {
          "run.googleapis.com/cloudsql-instances" = local.cloudsql_connection_name
        } : {}
      )
    }

    spec {
      service_account_name = google_service_account.run.email

      containers {
        image = each.value.image

        ports {
          container_port = each.value.port
        }

        resources {
          limits = {
            cpu    = each.value.cpu
            memory = each.value.memory
          }
        }

        dynamic "env" {
          for_each = merge(
            each.value.env,
            each.key == "alert-engine" &&
            contains(keys(each.value.env), "SCOPE_AUTH0") &&
            !contains(keys(each.value.env), "SCOPE_AUHT0")
              ? { SCOPE_AUHT0 = each.value.env["SCOPE_AUTH0"] }
              : {}
          )
          content {
            name  = env.key
            value = env.value
          }
        }

        dynamic "env" {
          for_each = each.value.secret_env
          content {
            name = env.key
            value_from {
              secret_key_ref {
                name = env.value
                key  = "latest"
              }
            }
          }
        }
      }
    }
  }

  traffic {
    latest_revision = true
    percent         = 100
  }

  autogenerate_revision_name = true
  depends_on                 = [google_project_service.apis]
}

resource "google_cloud_run_service_iam_member" "public_invoker" {
  for_each = var.pause_mode ? toset([]) : toset(var.public_services)

  location = var.region
  service  = google_cloud_run_service.services[each.key].name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_compute_region_network_endpoint_group" "frontend" {
  name                  = "${var.frontend_service_name}-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region

  cloud_run {
    service = google_cloud_run_service.services[var.frontend_service_name].name
  }
}

resource "google_compute_region_network_endpoint_group" "gateway" {
  name                  = "${var.gateway_service_name}-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region

  cloud_run {
    service = google_cloud_run_service.services[var.gateway_service_name].name
  }
}

resource "google_compute_backend_service" "frontend" {
  name                  = "notivest-frontend-backend"
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  timeout_sec           = 30

  backend {
    group = google_compute_region_network_endpoint_group.frontend.id
  }
}

resource "google_compute_backend_service" "gateway" {
  name                  = "notivest-gateway-backend"
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_region_network_endpoint_group.gateway.id
  }
}

resource "google_compute_url_map" "main" {
  name            = "notivest-url-map"
  default_service = google_compute_backend_service.frontend.id

  # Keep a single frontend host for auth cookies/state. Redirect www -> apex.
  host_rule {
    hosts        = ["www.${var.domain_root}"]
    path_matcher = "frontend-www-redirect"
  }

  host_rule {
    hosts        = [local.api_domain]
    path_matcher = "api"
  }

  path_matcher {
    name = "frontend-www-redirect"

    default_url_redirect {
      host_redirect          = var.domain_root
      https_redirect         = true
      redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
      strip_query            = false
    }
  }

  path_matcher {
    name            = "api"
    default_service = google_compute_backend_service.gateway.id
  }
}

resource "google_compute_url_map" "http_redirect" {
  name = "notivest-http-redirect"

  default_url_redirect {
    https_redirect = true
    strip_query    = false
  }
}

resource "google_compute_managed_ssl_certificate" "main" {
  name = "notivest-managed-cert"

  managed {
    domains = local.all_domains
  }
}

resource "google_compute_target_https_proxy" "main" {
  name             = "notivest-https-proxy"
  url_map          = google_compute_url_map.main.id
  ssl_certificates = [google_compute_managed_ssl_certificate.main.id]
}

resource "google_compute_target_http_proxy" "redirect" {
  name    = "notivest-http-proxy"
  url_map = google_compute_url_map.http_redirect.id
}

resource "google_compute_global_address" "lb_ip" {
  name = "notivest-lb-ip"
}

resource "google_compute_global_forwarding_rule" "https" {
  name                  = "notivest-https-forwarding-rule"
  ip_address            = google_compute_global_address.lb_ip.address
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  target                = google_compute_target_https_proxy.main.id
}

resource "google_compute_global_forwarding_rule" "http" {
  name                  = "notivest-http-forwarding-rule"
  ip_address            = google_compute_global_address.lb_ip.address
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  target                = google_compute_target_http_proxy.redirect.id
}
