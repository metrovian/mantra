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
  path_prepare
  validate_require_arg_count "$#" 1 "config profile remove <name>"
  validate_names "$1"
  require_profile "$1"
  clear_current_profile_if_selected "$1"
  remove_profile "$1"
  output_log "profile removed: $1"
}

main "$@"
