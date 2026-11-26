# The scripts and the GitHub workflow read these outputs to hand the
# connection details to Liquibase, the same way a real pipeline passes
# Terraform outputs to the next stage.

output "docker_network" {
  description = "Docker network the Liquibase container joins."
  value       = docker_network.poc.name
}

output "liquibase_jdbc_url" {
  description = "JDBC URL used by Liquibase from inside the Docker network."
  value       = "jdbc:postgresql://${docker_container.postgres.name}:5432/${postgresql_database.app.name}"
}

output "local_connection" {
  description = "Connection details for a GUI client (DBeaver, pgAdmin, VS Code) on your machine."
  value       = "host=localhost port=${var.host_port} dbname=${postgresql_database.app.name} user=${postgresql_role.app.name}"
}

output "app_username" {
  value = postgresql_role.app.name
}

output "app_password" {
  value     = var.app_password
  sensitive = true
}
