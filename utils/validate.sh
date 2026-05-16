validate_name() {
  case "$1" in
    ""|*[!a-zA-Z0-9._-]*)
      die "invalid name: $1"
      ;;
  esac
}

validate_names() {
  local name
  for name in "$@"; do
    validate_name "$name"
  done
}

require_arg_count() {
  local actual
  local expected
  actual=$1
  expected=$2
  if [ "$actual" -ne "$expected" ]; then
    die "usage: $3"
  fi
}

require_arg_max() {
  local actual
  local maximum
  actual=$1
  maximum=$2
  if [ "$actual" -gt "$maximum" ]; then
    die "usage: $3"
  fi
}
