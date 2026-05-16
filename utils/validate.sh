validate_name() {
  case "$1" in
    ""|*[!a-zA-Z0-9._-]*)
      output_die "invalid name: $1"
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
  args=$3
  if [ "$actual" -ne "$expected" ]; then
    output_die "$0 $args"
  fi
}

validate_require_arg_max() {
  local actual
  local maximum
  local args
  actual=$1
  maximum=$2
  args=$3
  if [ "$actual" -gt "$maximum" ]; then
    output_die "$0 $args"
  fi
}
