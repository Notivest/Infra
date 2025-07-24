variable "name"                  { type = string }
variable "resource_group_name"   { type = string }
variable "container_app_env_id"  { type = string }
variable "image"                 { type = string }
variable "cpu"                   { type = number default = 0.5 }
variable "memory"                { type = string  default = "1Gi" }
variable "revision_mode"         { type = string  default = "Single" }
variable "env_vars"              { type = map(string) default = {} }
variable "secret_map"            { type = map(string) default = {} }
variable "registry_server"       { type = string }
variable "identity_id"           { type = string }
variable "common_tags"           { type = map(string) }