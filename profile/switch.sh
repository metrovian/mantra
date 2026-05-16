set -eu

ROOT_DIR=$(
  cd "$(dirname "$0")/.."
  pwd
)

source "$ROOT_DIR/utils/output.sh"
source "$ROOT_DIR/utils/path.sh"
source "$ROOT_DIR/profile/common.sh"
source "$ROOT_DIR/utils/validate.sh"

main() {
  path_prepare
  validate_require_arg_count "$#" 1 "config profile switch <name>"
  validate_names "$1"
  profile_require "$1"
  profile_set_current "$1"
  output_log "profile switched: $1"
}

main "$@"
