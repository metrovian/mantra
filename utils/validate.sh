validate_names() {
  local name
  for name in "$@"; do
    case "$name" in
      ""|*[!a-zA-Z0-9._-]*)
        return 1
        ;;
    esac
  done
}
