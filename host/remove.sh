set -eu

ROOT_DIR=$(
  cd "$(dirname "$0")/.."
  pwd
)

source "$ROOT_DIR/utils/output.sh"
source "$ROOT_DIR/utils/path.sh"
source "$ROOT_DIR/profile/common.sh"
source "$ROOT_DIR/utils/validate.sh"
source "$ROOT_DIR/utils/ssh.sh"

main() {
  path_prepare
  validate_require_arg_count "$#" 2 "config host remove <profile> <alias>"
  validate_names "$1" "$2"
  profile_require "$1"
  require_host "$1" "$2"
  remove_host "$1" "$2"
  output_log "host removed: $2"
}

main "$@"
