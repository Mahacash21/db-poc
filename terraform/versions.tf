terraform {
  required_version = ">= 1.5.0"

  required_providers {
    # Manages Docker containers. Locally this stands in for the cloud provider
    # (azurerm) that would create an Azure Database for PostgreSQL server.
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }

    # Connects to Postgres to create the application database and login role.
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1.22"
    }
  }

  # State is kept in a local file (terraform.tfstate) for this POC.
  # In a real team setup this would be a remote backend, for example an
  # Azure Storage account (backend "azurerm"), so the pipeline and every
  # engineer share one copy of the state.
}
