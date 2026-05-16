profile_dir() {
  printf '%s/%s\n' "$MARIONETTE_PROFILES_DIR" "$1"
}

profile_hosts_file() {
  printf '%s/hosts\n' "$(profile_dir "$1")"
}

profile_known_hosts_file() {
  printf '%s/known_hosts\n' "$(profile_dir "$1")"
}

profile_ensure_known_hosts_file() {
  local known_hosts
  known_hosts=$(profile_known_hosts_file "$1")
  if [ ! -f "$known_hosts" ]; then
    : >"$known_hosts"
  fi
}

profile_exists() {
  [ -d "$(profile_dir "$1")" ]
}

profile_require() {
  if ! profile_exists "$1"; then
    output_die "profile not found: $1"
  fi
}

profile_current() {
  if [ ! -f "$MARIONETTE_CURRENT_PROFILE_FILE" ]; then
    return 1
  fi
  sed -n '1p' "$MARIONETTE_CURRENT_PROFILE_FILE"
}

profile_current_or_die() {
  profile_current || output_die "no active profile"
}

profile_set_current() {
  printf '%s\n' "$1" >"$MARIONETTE_CURRENT_PROFILE_FILE"
}

profile_clear_current_if_selected() {
  local current
  local profile
  profile=$1
  current=$(profile_current) || return 0
  if [ "$current" = "$profile" ]; then
    rm -f "$MARIONETTE_CURRENT_PROFILE_FILE"
  fi
}

profile_list() {
  local path
  if [ ! -d "$MARIONETTE_PROFILES_DIR" ]; then
    return 0
  fi
  for path in "$MARIONETTE_PROFILES_DIR"/*; do
    if [ -d "$path" ]; then
      basename "$path"
    fi
  done
}

profile_add() {
  local name
  name=$1
  mkdir -p "$(profile_dir "$name")"
  : >"$(profile_hosts_file "$name")"
  : >"$(profile_known_hosts_file "$name")"
}

profile_remove() {
  rm -rf "$(profile_dir "$1")"
}
