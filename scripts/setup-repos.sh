#!/usr/bin/env bash
set -Eeuo pipefail

# ---------------------------------------------------------------------------
# setup-repos.sh
# Manages local repository setup from a .env file containing REPO/DIR/HASH
# triplets. For each service it will:
#   - If DIR is set:    create or update a symlink in REPO_FOLDER -> DIR
#   - If DIR is unset:  git clone into REPO_FOLDER if not already present
#   - Always:           checkout the specified git hash/tag/branch
#
# Usage:
#   ./setup-repos.sh                        
#   REPO_FOLDER=~/repos ENV_FILE=.env.file ./setup-repos.sh
#
# Env file format (prefix must match entries in SERVICE_KEYS below):
#   API_REPO=https://github.com/org/repo
#   API_DIR=/path/to/local/source          # leave blank to clone
#   API_GIT_HASH=v2.22.0
# ---------------------------------------------------------------------------

ENV_FILE="${ENV_FILE:-.env}"
REPO_FOLDER="${REPO_FOLDER:-./repos}"

# --- Service key prefixes to process ---
# These must match the prefix used in the env file (e.g. API -> API_REPO, API_DIR, API_GIT_HASH)
SERVICE_KEYS=(
  API
  HPDS
  AUTH
  MIGRATIONS
  FRONTEND
  DICTIONARY
  DICTIONARY_ETL
  UPLOADER
  AGGREGATE
  PASSTHRU
)

# --- Counters ---
success=0
errors=0
skipped=0

# --- Error handler (non-fatal — we log and continue) ---
on_error() {
  echo "  ERROR: Unexpected failure on line $LINENO" >&2
  (( errors++ )) || true
}
trap on_error ERR

# --- Helpers ---
log_error()   { echo "  ERROR: $*" >&2; (( errors++  )) || true; }
log_skip()    { echo "  SKIP:  $*" >&2; (( skipped++ )) || true; }
log_ok()      { echo "  OK:    $*";     (( success++ )) || true; }

# --- Validate inputs ---
if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: env file not found: ${ENV_FILE}" >&2
  exit 1
fi

# Expand and create repo folder
REPO_FOLDER="${REPO_FOLDER/#\~/$HOME}"
mkdir -p "$REPO_FOLDER"

echo "Using env file:   ${ENV_FILE}"
echo "Using repo folder: ${REPO_FOLDER}"
echo ""

# --- Load env file (ignore comments and blank lines) ---
# We source it into a subshell-safe way to avoid polluting the environment
# with unrelated vars, but we need the values, so we source carefully.
set -o allexport
# shellcheck disable=SC1090
source "$ENV_FILE"
set +o allexport

# ---------------------------------------------------------------------------
# Process each service
# ---------------------------------------------------------------------------
for key in "${SERVICE_KEYS[@]}"; do
  repo_var="${key}_REPO"
  dir_var="${key}_DIR"
  hash_var="${key}_GIT_HASH"

  # Read values — default to empty string if unset
  repo="${!repo_var:-}"
  dir="${!dir_var:-}"
  git_hash="${!hash_var:-}"

  echo "[${key}]"

  # Skip entirely if no repo URL defined
  if [[ -z "$repo" ]]; then
    log_skip "No ${repo_var} defined, skipping."
    echo ""
    continue
  fi

  # Derive the target path in the repo folder from the repo name
  repo_name=$(basename "$repo" .git)
  repo_target="${REPO_FOLDER}/${repo_name}"

  # Expand ~ in dir if present
  [[ -n "$dir" ]] && dir="${dir/#\~/$HOME}"

  # -------------------------------------------------------------------------
  # DIR IS SET — symlink mode
  # -------------------------------------------------------------------------
  if [[ -n "$dir" ]]; then

    if [[ ! -d "$dir" ]]; then
      log_error "${dir_var} is set to '${dir}' but that directory does not exist."
      echo ""
      continue
    fi

    if [[ -L "$repo_target" ]]; then
      existing_link=$(readlink "$repo_target")
      if [[ "$existing_link" == "$dir" ]]; then
        log_ok "Symlink already correct: ${repo_target} -> ${dir}"
      else
        echo "  Updating symlink: ${repo_target} -> ${dir} (was ${existing_link})"
        rm "$repo_target"
        ln -s "$dir" "$repo_target"
        log_ok "Symlink updated."
      fi

    elif [[ -d "$repo_target" ]]; then
      log_error "${repo_target} is a real directory (cloned repo), not a symlink. Cannot replace with symlink to '${dir}'. Remove it manually."
      echo ""
      continue

    else
      echo "  Creating symlink: ${repo_target} -> ${dir}"
      ln -s "$dir" "$repo_target"
      log_ok "Symlink created."
    fi

  # -------------------------------------------------------------------------
  # DIR IS UNSET — clone mode
  # -------------------------------------------------------------------------
  else

    if [[ -L "$repo_target" ]]; then
      log_error "${repo_target} is a symlink but ${dir_var} is not set. Set ${dir_var} to manage this symlink, or remove it manually."
      echo ""
      continue

    elif [[ -d "$repo_target" ]]; then
      log_ok "Repo already cloned at ${repo_target}."

    else
      echo "  Cloning ${repo} into ${repo_target}..."
      if git clone "$repo" "$repo_target"; then
        log_ok "Cloned successfully."
      else
        log_error "git clone failed for ${repo}."
        echo ""
        continue
      fi
    fi

  fi

  # -------------------------------------------------------------------------
  # Checkout the specified hash/tag/branch (applies to both modes)
  # Resolve symlinks to the real path so git doesn't get confused
  # -------------------------------------------------------------------------
  if [[ -z "$git_hash" ]]; then
    log_skip "No ${hash_var} defined, skipping checkout."
  else
    real_target=$(realpath "$repo_target")
    echo "  Checking out ${git_hash}..."
    # force tags from remote to sync with local, even if divergent
    if git -C "$real_target" fetch --tags --force --quiet 2>/dev/null; then
      if git -C "$real_target" checkout "$git_hash" --quiet; then
        log_ok "Checked out ${git_hash}."
      else
        log_error "git checkout '${git_hash}' failed in ${real_target}."
      fi
    else
      log_error "git fetch failed in ${real_target} (network issue or not a real git repo?)."
    fi
  fi

  echo ""
done

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo "----------------------------------------"
echo "Done. ${success} OK, ${skipped} skipped, ${errors} error(s)."
if (( errors > 0 )); then
  exit 1
fi
