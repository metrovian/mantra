#!/usr/bin/env bash
set -eu

ROOT_DIR=$(
  cd "$(dirname "$0")/.."
  pwd
)

. "$ROOT_DIR/utils/output.sh"
. "$ROOT_DIR/utils/path.sh"
. "$ROOT_DIR/utils/validate.sh"
. "$ROOT_DIR/utils/config.sh"

main() {
  if [ "$#" -ne 1 ]; then
    die "usage: config profile add <name>"
  fi
  marionette_init_paths
  validate_name "$1"
  if profile_exists "$1"; then
    die "profile already exists: $1"
  fi
  create_profile "$1"
  log "profile added: $1"
}

main "$@"
