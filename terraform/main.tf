provider "docker" {
  host = var.docker_host != "" ? var.docker_host : null
}

# Connects as the superuser through the port published on your machine.
provider "postgresql" {
  host            = "localhost"
  port            = var.host_port
  username        = "postgres"
  password        = var.pg_admin_password
  sslmode         = "disable"
  connect_timeout = 15
}

# ---------------------------------------------------------------------------
# Layer 1: the "server". In the cloud this would be an
# azurerm_postgresql_flexible_server plus its network rules.
# ---------------------------------------------------------------------------

resource "docker_network" "poc" {
  name = var.network_name
}

resource "docker_volume" "pgdata" {
  name = "${var.container_name}-data"
}

resource "docker_image" "postgres" {
  name         = var.postgres_image
  keep_locally = true
}

resource "docker_container" "postgres" {
  name    = var.container_name
  image   = docker_image.postgres.image_id
  restart = "unless-stopped"

  env = [
    "POSTGRES_PASSWORD=${var.pg_admin_password}",
  ]

  ports {
    internal = 5432
    external = var.host_port
  }

  networks_advanced {
    name = docker_network.poc.name
  }

  volumes {
    volume_name    = docker_volume.pgdata.name
    container_path = "/var/lib/postgresql/data"
  }

  healthcheck {
    test     = ["CMD-SHELL", "pg_isready -U postgres"]
    interval = "2s"
    timeout  = "5s"
    retries  = 30
  }

  # Don't report success until Postgres accepts connections, so the
  # postgresql provider below can connect straight away.
  wait         = true
  wait_timeout = 90
}

# ---------------------------------------------------------------------------
# Layer 2: the empty database and its owner. Terraform stops here.
# Tables are Liquibase's job.
# ---------------------------------------------------------------------------

resource "postgresql_role" "app" {
  name     = var.app_username
  login    = true
  password = var.app_password

  depends_on = [docker_container.postgres]
}

resource "postgresql_database" "app" {
  name  = var.app_database
  owner = postgresql_role.app.name

  depends_on = [docker_container.postgres]
}
