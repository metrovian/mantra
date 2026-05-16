set -eu

ROOT_DIR=$(
  cd "$(dirname "$0")/.."
  pwd
)

usage() {
  cat <<'EOF'
usage:
  config host list [profile]
  config host add <profile> <alias> <user> <hostname>
  config host remove <profile> <alias>
EOF
}

main() {
  if [ "$#" -eq 0 ]; then
    usage
    exit 1
  fi
  case "$1" in
    list)
      shift
      bash "$ROOT_DIR/host/list.sh" "$@"
      ;;
    add)
      shift
      bash "$ROOT_DIR/host/add.sh" "$@"
      ;;
    remove)
      shift
      bash "$ROOT_DIR/host/remove.sh" "$@"
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
