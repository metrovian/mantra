#!/usr/bin/env bash
set -eu

ROOT_DIR=$(
  cd "$(dirname "$0")/.."
  pwd
)

. "$ROOT_DIR/utils/output.sh"
. "$ROOT_DIR/utils/path.sh"
. "$ROOT_DIR/utils/config.sh"
. "$ROOT_DIR/utils/table.sh"

main() {
  local current
  local name
  marionette_init_paths
  current=""
  if current=$(current_profile); then
    :
  fi
  table_reset
  table_set_headers profile current
  for name in $(list_profiles); do
    if [ "$name" = "$current" ]; then
      table_add_row "$name" yes
    else
      table_add_row "$name" ""
    fi
  done
  table_print
}

main "$@"
