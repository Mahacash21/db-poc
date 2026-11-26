# Database POC: GitHub + Terraform + Liquibase + Postgres

A small, local copy of the setup your team is planning, built so you can learn how the pieces fit before doing it for real.

| Real world (your team)                  | This POC                                    |
|-----------------------------------------|---------------------------------------------|
| Azure Database for PostgreSQL           | Postgres 16 in a Docker Desktop container   |
| Terraform with the `azurerm` provider   | Terraform with the `docker` provider        |
| Liquibase changelogs                    | Liquibase changelogs (identical)            |
| Azure DevOps repo + pipeline            | GitHub repo + GitHub Actions workflow       |
| Key Vault / ADO variable groups         | `terraform.tfvars` locally, GitHub Secrets in CI |
| Remote Terraform state (Azure Storage)  | Local `terraform.tfstate` file              |

The Liquibase part transfers to the real project as-is. For Terraform, only the provider and resource types change.

## What happens

1. **Terraform** (`terraform/`) creates a Docker network, a data volume, a Postgres container, an `appdb` database and an `app_user` login that owns it. It stops at an empty database.
2. **Liquibase** (`liquibase/changelog/`) connects as `app_user` and creates the `customers` and `orders` tables plus some sample rows. It records what it ran in a `databasechangelog` table, so each change only ever runs once.
3. **GitHub Actions** (`.github/workflows/database.yml`) runs that same chain on every push, inside a throwaway runner, so a broken change is caught before it reaches a real database.

## Prerequisites (Windows)

- Docker Desktop, running
- Terraform: `winget install Hashicorp.Terraform` (open a new terminal afterwards, then check with `terraform -version`)
- Git, and a GitHub account
- Optional: a SQL client such as DBeaver, pgAdmin or the VS Code PostgreSQL extension

You don't need to install Liquibase or Java. Liquibase runs in a Docker container.

## Run it locally

From PowerShell in the project folder:

```powershell
# 1. Set your passwords (this file is git-ignored)
Copy-Item terraform\terraform.tfvars.example terraform\terraform.tfvars
notepad terraform\terraform.tfvars

# 2. Build everything: Postgres first, then the tables
.\scripts\poc.ps1 up
```

If PowerShell blocks the script, run it once with
`powershell -ExecutionPolicy Bypass -File .\scripts\poc.ps1 up`.

When it finishes you'll see the table list. Other commands:

| Command                        | What it does                                      |
|--------------------------------|---------------------------------------------------|
| `.\scripts\poc.ps1 status`     | Lists Liquibase changes that haven't run yet      |
| `.\scripts\poc.ps1 migrate`    | Applies pending changes only                      |
| `.\scripts\poc.ps1 rollback`   | Undoes the most recent change                     |
| `.\scripts\poc.ps1 tables`     | Shows the tables                                  |
| `.\scripts\poc.ps1 psql`       | Opens a SQL prompt (`\q` to quit)                 |
| `.\scripts\poc.ps1 down`       | Deletes the container, data and network           |

To connect a GUI client, use host `localhost`, port `5433`, database `appdb`, user `app_user` and the `app_password` from your tfvars.

## Put it on GitHub

```powershell
git init -b main
git add .
git commit -m "Database POC: Terraform + Liquibase + Postgres"
# Create an empty repo on github.com (no README), then:
git remote add origin https://github.com/<your-user>/db-poc.git
git push -u origin main
```

Open the repo's **Actions** tab to watch `database-pipeline` run. Optionally add `PG_ADMIN_PASSWORD` and `PG_APP_PASSWORD` under Settings > Secrets and variables > Actions. Without them the workflow uses throwaway CI passwords.

## Try the real workflow: add a table

This is the day-to-day loop your team will follow:

1. Create a branch: `git checkout -b add-products`
2. Add `liquibase/changelog/changes/004-create-products.sql`:

   ```sql
   --liquibase formatted sql

   --changeset yourname:004-create-products
   CREATE TABLE products (
       product_id  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
       sku         VARCHAR(50)  NOT NULL UNIQUE,
       name        VARCHAR(200) NOT NULL,
       price       NUMERIC(12,2) NOT NULL
   );
   --rollback DROP TABLE products;
   ```

3. List it at the bottom of `db.changelog-master.yaml`.
4. Run `.\scripts\poc.ps1 status` (shows 1 pending change), then `.\scripts\poc.ps1 migrate`.
5. Push the branch and open a pull request. The workflow builds a fresh database, applies changes 001 to 004, and tests that your rollback works.

Rules worth adopting from day one:

- **Never edit a changeset that has already run.** Liquibase stores a checksum and will refuse to continue. Fix mistakes with a new changeset.
- **Always write a `--rollback`.** The pipeline tests it.
- **Use a unique `author:id`** on each changeset.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `error during connect` / `Cannot connect to the Docker daemon` | Start Docker Desktop and wait until it says it's running. |
| `port is already allocated` | Something else uses 5433. Set `host_port = 5434` in `terraform.tfvars`. |
| Terraform can't find Docker on Windows | Add `docker_host = "npipe:////./pipe/docker_engine"` to `terraform.tfvars`. |
| `checksum ... has changed` | Someone edited an applied changeset. Revert the edit and add a new changeset. |
| `terraform` not recognised after installing | Open a new terminal so the updated PATH loads. |

## Stretch goals (closer to the real setup)

- **Self-hosted runner.** Register your laptop as a GitHub Actions runner (Settings > Actions > Runners) and point the workflow at it. This mirrors the ADO situation where a cloud database sits on a private network, so Microsoft-hosted agents can't reach it and a self-hosted agent is required.
- **Environments and approvals.** Add a GitHub Environment named `prod` with a required reviewer, then gate the `update` step on it. This is the same idea as ADO environment approvals.
- **Remote state.** Move Terraform state to a shared backend so the pipeline and every engineer see the same state.
- **Swap the provider.** Replace the Docker resources with `azurerm_postgresql_flexible_server` and `azurerm_postgresql_flexible_server_database`. The Liquibase folder doesn't change at all.
