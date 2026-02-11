variable "project_id" {
  type        = string
  description = "GCP project id."
}

variable "region" {
  type        = string
  description = "GCP region."
  default     = "southamerica-east1"
}

variable "domain_root" {
  type        = string
  description = "Root domain for the frontend (ex: notivest.com)."
}

variable "frontend_service_name" {
  type        = string
  description = "Cloud Run service name for the frontend."
  default     = "frontend"
}

variable "gateway_service_name" {
  type        = string
  description = "Cloud Run service name for the gateway."
  default     = "gateway-api"
}

variable "public_services" {
  type        = list(string)
  description = "Cloud Run services that allow unauthenticated access."
  default     = []
}

variable "pause_mode" {
  type        = bool
  description = "When true, pauses runtime workloads without destroying infrastructure."
  default     = false
}

variable "pause_cloud_sql" {
  type        = bool
  description = "When true and pause_mode is enabled, Cloud SQL activation policy is set to NEVER."
  default     = false
}

variable "services" {
  type = map(object({
    image         = string
    port          = number
    cpu           = string
    memory        = string
    min_instances = number
    max_instances = number
    env           = optional(map(string), {})
    secret_env    = optional(map(string), {})
  }))
  description = "Cloud Run services configuration."
}

variable "secret_values" {
  type        = map(string)
  description = "Optional secret values to create secret versions (stored in state)."
  default     = {}
  sensitive   = true
}

variable "enable_cloud_sql" {
  type        = bool
  description = "Whether to create Cloud SQL."
  default     = true
}

variable "cloudsql_instance_name" {
  type        = string
  description = "Cloud SQL instance name."
  default     = "notivest-postgres"
}

variable "cloudsql_version" {
  type        = string
  description = "Postgres version."
  default     = "POSTGRES_14"
}

variable "cloudsql_tier" {
  type        = string
  description = "Instance tier."
  default     = "db-g1-small"
}

variable "cloudsql_disk_gb" {
  type        = number
  description = "Disk size in GB."
  default     = 20
}

variable "cloudsql_databases" {
  type        = list(string)
  description = "List of database names to create."
  default     = []
}

variable "cloudsql_users" {
  type        = map(string)
  description = "Map of db user => password."
  default     = {}
  sensitive   = true
}

variable "cloudsql_deletion_protection" {
  type        = bool
  description = "Cloud SQL deletion protection."
  default     = true
}
