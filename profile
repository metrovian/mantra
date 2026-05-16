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
  path_prepare
  profile_print_table
}

main "$@"
