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
  if [ "$#" -ne 4 ]; then
    die "usage: config host add <profile> <alias> <user> <hostname>"
  fi
  marionette_init_paths
  validate_name "$1"
  validate_name "$2"
  validate_name "$3"
  if ! profile_exists "$1"; then
    die "profile not found: $1"
  fi
  if host_exists "$1" "$2"; then
    die "host already exists: $2"
  fi
  add_host "$1" "$2" "$3" "$4"
  log "host added: $2"
}

main "$@"
