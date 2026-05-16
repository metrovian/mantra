#!/usr/bin/env bash
set -eu

ROOT_DIR=$(
  cd "$(dirname "$0")"
  pwd
)

source "$ROOT_DIR/utils/source.sh"
source_modules \
  utils/path.sh \
  utils/table.sh \
  profiles/common.sh

main() {
  local current
  local name
  path_prepare
  current=""
  if current=$(profile_current); then
    :
  fi
  table_reset
  table_set_headers profile current
  for name in $(profile_list); do
    if [ "$name" = "$current" ]; then
      table_add_row "$name" yes
    else
      table_add_row "$name" ""
    fi
  done
  table_print
}

main "$@"
