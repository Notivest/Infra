variable "name"               { type = string }
variable "db_name"            { type = string }
variable "admin_user"         { type = string default = "pgadmin" }
variable "resource_group_name"{ type = string }
variable "location"           { type = string }
variable "environment"        { type = string }
variable "common_tags"        { type = map(string) }
