variable "docker_host" {
  description = "Docker daemon address. Leave empty to use the provider default (Docker Desktop on Windows/macOS, the Unix socket on Linux)."
  type        = string
  default     = ""
}

variable "postgres_image" {
  description = "Postgres image to run."
  type        = string
  default     = "postgres:16"
}

variable "host_port" {
  description = "Port on your machine that maps to Postgres inside the container. 5433 avoids clashing with any Postgres you already run on 5432."
  type        = number
  default     = 5433
}

variable "container_name" {
  description = "Name of the Postgres container (also its hostname on the Docker network)."
  type        = string
  default     = "poc-postgres"
}

variable "network_name" {
  description = "Docker network shared by Postgres and the Liquibase container."
  type        = string
  default     = "poc-net"
}

variable "pg_admin_password" {
  description = "Password for the built-in 'postgres' superuser. Terraform uses it; your application never should."
  type        = string
  sensitive   = true
}

variable "app_database" {
  description = "Name of the application database that Liquibase builds tables in."
  type        = string
  default     = "appdb"
}

variable "app_username" {
  description = "Login role that owns the application database. Liquibase connects as this user."
  type        = string
  default     = "app_user"
}

variable "app_password" {
  description = "Password for the application login role."
  type        = string
  sensitive   = true
}
