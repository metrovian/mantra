source_modules() {
  local module
  for module in "$@"; do
    source "$ROOT_DIR/$module"
  done
}
