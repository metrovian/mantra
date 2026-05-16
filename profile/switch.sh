#!/usr/bin/env bash
set -eu

ROOT_DIR=$(
  cd "$(dirname "$0")/.."
  pwd
)

. "$ROOT_DIR/utils/output.sh"
. "$ROOT_DIR/utils/path.sh"
. "$ROOT_DIR/utils/config.sh"
. "$ROOT_DIR/utils/validate.sh"

main() {
  if [ "$#" -ne 1 ]; then
    die "usage: marionette profile switch <name>"
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
