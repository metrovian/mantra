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

validate_hostname() {
  local hostname
  hostname=$1
  case "$hostname" in
    ""|-*|*[!a-zA-Z0-9._:%-]*)
      return 1
      ;;
  esac
}
