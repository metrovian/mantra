#!/usr/bin/env bash
set -eu

ROOT_DIR=$(
  cd "$(dirname "$0")/.."
  pwd
)

. "$ROOT_DIR/utils/output.sh"
. "$ROOT_DIR/utils/path.sh"
. "$ROOT_DIR/utils/config.sh"
. "$ROOT_DIR/utils/ssh.sh"
. "$ROOT_DIR/utils/table.sh"

main() {
  local profile
  local row
  local alias
  local user
  local hostname
  marionette_init_paths
  if [ "$#" -gt 1 ]; then
    die "usage: config host list [profile]"
  fi
  if [ "$#" -eq 1 ]; then
    profile=$1
  else
    profile=$(current_profile) || die "no active profile"
  fi
  if ! profile_exists "$profile"; then
    die "profile not found: $profile"
  fi
  table_reset
  table_set_headers alias user hostname
  while IFS=$'\t' read -r alias user hostname; do
    [ -n "$alias" ] || continue
    table_add_row "$alias" "$user" "$hostname"
  done <<EOF
$(list_hosts "$profile")
EOF
  table_print
}

main "$@"
