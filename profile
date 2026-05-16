#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

source "$ROOT_DIR/utils/source.sh"
source_modules \
  utils/path.sh \
  utils/table.sh \
  profiles/common.sh \
  hosts/common.sh

main() {
  local name
  path_prepare
  table_reset
  table_set_headers PROFILE HOST
  for name in $(profile_list); do
    table_add_row "$name" "$(host_count "$name")"
  done
  table_print
}

main "$@"
