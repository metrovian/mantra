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
  path_prepare
  validate_require_arg_count "$#" 1 "config profile add <name>"
  validate_names "$1"
  if profile_exists "$1"; then
    output_die "profile already exists: $1"
  fi
  create_profile "$1"
  output_log "profile added: $1"
}

main "$@"
