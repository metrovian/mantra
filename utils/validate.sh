validate_name() {
  case "$1" in
    ""|*[!a-zA-Z0-9._-]*)
      return 1
      ;;
  esac
}

validate_names() {
  local name
  for name in "$@"; do
    validate_name "$name"
  done
}

validate_require_arg_count() {
  local actual
  local expected
  actual=$1
  expected=$2
  [ "$actual" -eq "$expected" ]
}

validate_require_arg_max() {
  local actual
  local maximum
  actual=$1
  maximum=$2
  [ "$actual" -le "$maximum" ]
}
