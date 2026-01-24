output "load_balancer_ip" {
  value       = google_compute_global_address.lb_ip.address
  description = "Global IP address for the external load balancer."
}

output "frontend_domains" {
  value       = local.frontend_domains
  description = "Frontend domains routed to the frontend service."
}

output "api_domain" {
  value       = local.api_domain
  description = "API domain routed to the gateway service."
}

output "cloud_run_urls" {
  value = {
    for name, service in google_cloud_run_service.services :
    name => service.status[0].url
  }
  description = "Direct Cloud Run URLs per service."
}

output "cloudsql_connection_name" {
  value       = var.enable_cloud_sql ? google_sql_database_instance.primary[0].connection_name : null
  description = "Cloud SQL connection name."
}
