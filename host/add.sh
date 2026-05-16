set -eu

ROOT_DIR=$(
  cd "$(dirname "$0")/.."
  pwd
)

source "$ROOT_DIR/utils/output.sh"
source "$ROOT_DIR/utils/path.sh"
source "$ROOT_DIR/utils/config.sh"
source "$ROOT_DIR/utils/validate.sh"
source "$ROOT_DIR/utils/ssh.sh"

main() {
  marionette_prepare
  require_arg_count "$#" 4 "config host add <profile> <alias> <user> <hostname>"
  validate_names "$1" "$2" "$3"
  require_profile "$1"
  if host_exists "$1" "$2"; then
    die "host already exists: $2"
  fi
  add_host "$1" "$2" "$3" "$4"
  log "host added: $2"
}

main "$@"
