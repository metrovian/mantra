set -eu

ROOT_DIR=$(
  cd "$(dirname "$0")/.."
  pwd
)

usage() {
  cat <<'EOF'
usage:
  config profile list
  config profile add <name>
  config profile remove <name>
  config profile switch <name>
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
      bash "$ROOT_DIR/profile/list.sh" "$@"
      ;;
    add)
      shift
      bash "$ROOT_DIR/profile/add.sh" "$@"
      ;;
    remove)
      shift
      bash "$ROOT_DIR/profile/remove.sh" "$@"
      ;;
    switch)
      shift
      bash "$ROOT_DIR/profile/switch.sh" "$@"
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
