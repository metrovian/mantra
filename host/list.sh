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
  marionette_init_paths
  if [ "$#" -gt 1 ]; then
    die "usage: marionette host list [profile]"
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
  table_set_headers alias hostname
  while IFS= read -r row; do
    [ -n "$row" ] || continue
    table_add_row $(printf '%s\n' "$row" | awk -F '\t' '{ print $1, $2 }')
  done <<EOF
$(list_hosts "$profile")
EOF
  table_print
}

main "$@"
