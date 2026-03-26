#!/usr/bin/env bash
set -Eeuo pipefail

# ---------------------------------------------------------------------------
# setup.sh
# Orchestrates environment setup: writes config, updates git hashes, and
# sets up local repositories.
#
# Usage:
#   ./setup.sh                                  # uses default build-spec.json
#   ./setup.sh ./path/to/build-spec.json
#   ./setup.sh https://example.com/build-spec.json
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_SPEC="${1:-}"

# --- Error handler ---
on_error() {
  echo "ERROR: setup.sh failed on line $LINENO" >&2
}
trap on_error ERR

# --- Write docker config env file ---
echo "## ---- Docker Config" > .env.config

if [[ ! -f .env.config ]] || [[ -z "${DOCKER_CONFIG_DIR:-}" ]]; then
  DOCKER_CONFIG_DIR="${DOCKER_CONFIG_DIR:-/usr/local/docker-config}"
  MYSQL_CONFIG_DIR="${MYSQL_CONFIG_DIR:-${DOCKER_CONFIG_DIR}/picsure-db/}"
  # Use this for file system checks. Use DOCKER_CONFIG_DIR for docker commands.
  # Except for --env-file commands, which refer to the current file system, not the root fs
  CURRENT_FS_DOCKER_CONFIG_DIR="${CURRENT_FS_DOCKER_CONFIG_DIR:-${DOCKER_CONFIG_DIR}}"
fi

{
  echo "## ---- Docker Config"
  echo "DOCKER_CONFIG_DIR=${DOCKER_CONFIG_DIR}"
  echo "MYSQL_CONFIG_DIR=${MYSQL_CONFIG_DIR}"
  echo "CURRENT_FS_DOCKER_CONFIG_DIR=${CURRENT_FS_DOCKER_CONFIG_DIR}"
} > .env.config

# --- Update git hashes from build-spec ---
ENV_FILE=.env.repos "${SCRIPT_DIR}/scripts/update-hashes.sh" "${BUILD_SPEC}"

# --- Merge config and repo env files ---
cat .env.config .env.repos > .env

# --- Set up repositories ---
"${SCRIPT_DIR}/scripts/setup-repos.sh"