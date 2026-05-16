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
  local args
  actual=$1
  expected=$2
  if [ "$actual" -ne "$expected" ]; then
    return 1
  fi
}

validate_require_arg_max() {
  local actual
  local maximum
  local args
  actual=$1
  maximum=$2
  if [ "$actual" -gt "$maximum" ]; then
    return 1
  fi
}
