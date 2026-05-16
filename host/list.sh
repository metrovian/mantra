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
source "$ROOT_DIR/utils/table.sh"

main() {
  local profile
  path_prepare
  validate_require_arg_max "$#" 1 "config host list [profile]"
  if [ "$#" -eq 1 ]; then
    profile=$1
  else
    profile=$(current_profile_or_die)
  fi
  require_profile "$profile"
  table_reset
  table_set_headers alias user hostname
  each_host "$profile" table_add_row
  table_print
}

main "$@"
