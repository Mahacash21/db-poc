#!/usr/bin/env bash
# Runs Liquibase in Docker against the database Terraform created.
# Used by the GitHub Actions workflow; also works on macOS/Linux/WSL.
#
#   ./scripts/liquibase.sh update
#   ./scripts/liquibase.sh status --verbose
#   ./scripts/liquibase.sh rollback-count --count=1
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TF_DIR="$ROOT/terraform"
IMAGE="${LIQUIBASE_IMAGE:-liquibase:4.33.0}"

tf_out() { terraform -chdir="$TF_DIR" output -raw "$1"; }

NET="$(tf_out docker_network)"
URL="$(tf_out liquibase_jdbc_url)"
USER_NAME="$(tf_out app_username)"
PASSWORD="$(tf_out app_password)"

docker run --rm --network "$NET" \
  -v "$ROOT/liquibase/changelog:/liquibase/changelog" \
  "$IMAGE" \
  --search-path=/liquibase/changelog \
  --changelog-file=db.changelog-master.yaml \
  --url="$URL" --username="$USER_NAME" --password="$PASSWORD" \
  "$@"
