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
      bash "$ROOT_DIR/profiles/list.sh" "$@"
      ;;
    add)
      shift
      bash "$ROOT_DIR/profiles/add.sh" "$@"
      ;;
    remove)
      shift
      bash "$ROOT_DIR/profiles/remove.sh" "$@"
      ;;
    switch)
      shift
      bash "$ROOT_DIR/profiles/switch.sh" "$@"
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
