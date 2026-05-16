set -eu

ROOT_DIR=$(
  cd "$(dirname "$0")/.."
  pwd
)

source "$ROOT_DIR/utils/output.sh"
source "$ROOT_DIR/utils/path.sh"
source "$ROOT_DIR/utils/validate.sh"
source "$ROOT_DIR/utils/config.sh"

main() {
  marionette_prepare
  require_arg_count "$#" 1 "config profile add <name>"
  validate_names "$1"
  if profile_exists "$1"; then
    die "profile already exists: $1"
  fi
  create_profile "$1"
  log "profile added: $1"
}

main "$@"
