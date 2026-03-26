#!/usr/bin/env bash
set -Eeuo pipefail

# ---------------------------------------------------------------------------
# update-hashes.sh
# Updates git hash values in a .env file from a local or remote build-spec.json
#
# Usage:
#   ./update-hashes.sh                          # uses default local build-spec.json
#   ./update-hashes.sh ./path/to/build-spec.json
#   ./update-hashes.sh https://example.com/build-spec.json
#   ENV_FILE=.env.file ./update-hashes.sh ...
#
# The build-spec maps project_job_git_key -> env var prefix, e.g.:
#   PSA  -> API_GIT_HASH
#   PSH  -> HPDS_GIT_HASH
# ---------------------------------------------------------------------------

ENV_FILE="${ENV_FILE:-.env}"
BUILDSPEC="${1:-./build-spec.json}"

# --- Key map: project_job_git_key -> env var name ---
# Uses a function with case statement for bash 3 compatibility (no declare -A)
lookup_env_var() {
  case "$1" in
    PSA)            echo "API_GIT_HASH" ;;
    PSH)            echo "HPDS_GIT_HASH" ;;
    PSAMA)          echo "AUTH_GIT_HASH" ;;
    PSM)            echo "MIGRATIONS_GIT_HASH" ;;
    PSF)            echo "FRONTEND_GIT_HASH" ;;
    DICTIONARY)     echo "DICTIONARY_GIT_HASH" ;;
    DICTIONARY_ETL) echo "DICTIONARY_ETL_GIT_HASH" ;;
    UPLOADER)       echo "UPLOADER_GIT_HASH" ;;
    AGGREGATE)      echo "AGGREGATE_GIT_HASH" ;;
    PASSTHRU)       echo "PASSTHRU_GIT_HASH" ;;
    *)              echo "" ;;
  esac
}

# --- Replace a key's value in the env file ---
replace_env_value() {
  local key="$1" value="$2"
  local tmp
  tmp=$(mktemp)
  sed "s|^${key}=.*|${key}=${value}|" "$ENV_FILE" > "$tmp" && mv "$tmp" "$ENV_FILE"
}

# --- Error handler ---
on_error() {
  echo "ERROR: Script failed on line $LINENO" >&2
}
trap on_error ERR

# --- Dependency check ---
if ! command -v jq &>/dev/null; then
  echo "ERROR: jq is required but not installed." >&2
  exit 1
fi

# --- Load build-spec (local file or remote URL) ---
echo "Loading build-spec from: ${BUILDSPEC}"

if [[ "$BUILDSPEC" =~ ^https?:// ]]; then
  if ! command -v curl &>/dev/null; then
    echo "ERROR: curl is required for remote build-specs." >&2
    exit 1
  fi
  BUILDSPEC_CONTENT=$(curl -fsSL "$BUILDSPEC") || {
    echo "ERROR: Failed to fetch remote build-spec: ${BUILDSPEC}" >&2
    exit 1
  }
else
  if [[ ! -f "$BUILDSPEC" ]]; then
    echo "ERROR: Local build-spec not found: ${BUILDSPEC}" >&2
    exit 1
  fi
  BUILDSPEC_CONTENT=$(cat "$BUILDSPEC")
fi

# --- Validate env file exists ---
if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: .env file not found: ${ENV_FILE}" >&2
  exit 1
fi

echo "Updating hashes in: ${ENV_FILE}"

# --- Process each entry in the build-spec ---
updated=0
skipped=0

while IFS= read -r entry; do
  job_key=$(echo "$entry" | jq -r '.project_job_git_key')
  git_hash=$(echo "$entry" | jq -r '.git_hash')

  env_var=$(lookup_env_var "$job_key")

  if [[ -z "$env_var" ]]; then
    echo "  SKIP: No mapping for key '${job_key}'" >&2
    (( skipped++ )) || true
    continue
  fi

  if grep -q "^${env_var}=" "$ENV_FILE"; then
    # Update existing entry
    replace_env_value "$env_var" "$git_hash"
    echo "  SET:  ${env_var}=${git_hash}"
  else
    # Append if missing
    echo "${env_var}=${git_hash}" >> "$ENV_FILE"
    echo "  ADD:  ${env_var}=${git_hash}"
  fi

  (( updated++ )) || true

done < <(echo "$BUILDSPEC_CONTENT" | jq -c '.application[]')

echo ""
echo "Done. ${updated} updated, ${skipped} skipped."
