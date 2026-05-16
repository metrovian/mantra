set -eu

ROOT_DIR=$(
  cd "$(dirname "$0")/.."
  pwd
)

source "$ROOT_DIR/utils/output.sh"
source "$ROOT_DIR/utils/path.sh"
source "$ROOT_DIR/utils/config.sh"
source "$ROOT_DIR/utils/validate.sh"

main() {
  marionette_prepare
  require_arg_count "$#" 1 "config profile switch <name>"
  validate_names "$1"
  require_profile "$1"
  set_current_profile "$1"
  log "profile switched: $1"
}

main "$@"
