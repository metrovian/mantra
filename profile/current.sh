#!/usr/bin/env bash
set -eu

ROOT_DIR=$(
  cd "$(dirname "$0")/.."
  pwd
)

. "$ROOT_DIR/utils/output.sh"
. "$ROOT_DIR/utils/path.sh"
. "$ROOT_DIR/utils/config.sh"
. "$ROOT_DIR/utils/pair.sh"

main() {
  local current
  marionette_init_paths
  pair_reset
  pair_set_title current
  if current=$(current_profile); then
    pair_add profile "$current"
    pair_add path "$(profile_dir "$current")"
  else
    pair_add profile "(none)"
  fi
  pair_print
}

main "$@"
