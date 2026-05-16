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
source "$ROOT_DIR/utils/ssh.sh"
source "$ROOT_DIR/utils/table.sh"

main() {
  local profile
  marionette_prepare
  require_arg_max "$#" 1 "config host list [profile]"
  if [ "$#" -eq 1 ]; then
    profile=$1
  else
    profile=$(current_profile) || die "no active profile"
  fi
  require_profile "$profile"
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
