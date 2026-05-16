#!/usr/bin/env bash
set -eu

ROOT_DIR=$(
  cd "$(dirname "$0")/.."
  pwd
)

source "$ROOT_DIR/utils/output.sh"
source "$ROOT_DIR/utils/path.sh"
source "$ROOT_DIR/utils/config.sh"
source "$ROOT_DIR/utils/table.sh"

main() {
  local current
  local name
  marionette_prepare
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
