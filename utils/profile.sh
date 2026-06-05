profile_dir() {
  printf '%s/%s\n' "$MANTRA_PROFILES_DIR" "$1"
}

profile_hosts_file() {
  printf '%s/hosts\n' "$(profile_dir "$1")"
}

profile_known_hosts_file() {
  printf '%s/known_hosts\n' "$(profile_dir "$1")"
}

profile_exists() {
  [ -d "$(profile_dir "$1")" ]
}

profile_require() {
  profile_exists "$1"
}

profile_current() {
  if [ ! -f "$MANTRA_CURRENT_PROFILE_FILE" ]; then
    return 1
  fi
  sed -n '1p' "$MANTRA_CURRENT_PROFILE_FILE"
}

profile_set_current() {
  printf '%s\n' "$1" >"$MANTRA_CURRENT_PROFILE_FILE"
}

profile_clear_current_if_selected() {
  local current
  local profile
  profile=$1
  current=$(profile_current) || return 0
  if [ "$current" = "$profile" ]; then
    rm -f "$MANTRA_CURRENT_PROFILE_FILE"
  fi
}

profile_list() {
  local path
  if [ ! -d "$MANTRA_PROFILES_DIR" ]; then
    return 0
  fi
  for path in "$MANTRA_PROFILES_DIR"/*; do
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
