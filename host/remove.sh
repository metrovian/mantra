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
. "$ROOT_DIR/utils/ssh.sh"

main() {
  if [ "$#" -ne 2 ]; then
    die "usage: marionette host remove <profile> <alias>"
  fi
  marionette_init_paths
  validate_name "$1"
  validate_name "$2"
  if ! profile_exists "$1"; then
    die "profile not found: $1"
  fi
  if ! host_exists "$1" "$2"; then
    die "host not found: $2"
  fi
  remove_host "$1" "$2"
  log "host removed: $2"
}

main "$@"
