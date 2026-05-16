#!/usr/bin/env bash
set -eu

ROOT_DIR=$(
  cd "$(dirname "$0")/.."
  pwd
)

source "$ROOT_DIR/utils/output.sh"
source "$ROOT_DIR/utils/path.sh"
source "$ROOT_DIR/utils/config.sh"
source "$ROOT_DIR/utils/validate.sh"

main() {
  if [ "$#" -ne 1 ]; then
    die "usage: config profile switch <name>"
  fi
  marionette_init_paths
  validate_name "$1"
  if ! profile_exists "$1"; then
    die "profile not found: $1"
  fi
  set_current_profile "$1"
  log "profile switched: $1"
}

main "$@"
