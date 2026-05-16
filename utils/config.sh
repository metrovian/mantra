profile_dir() {
  printf '%s/%s\n' "$MARIONETTE_PROFILES_DIR" "$1"
}

profile_hosts_file() {
  printf '%s/hosts\n' "$(profile_dir "$1")"
}

profile_known_hosts_file() {
  printf '%s/known_hosts_%s\n' "$MARIONETTE_STATE_DIR" "$1"
}

profile_exists() {
  [ -d "$(profile_dir "$1")" ]
}

require_profile() {
  if ! profile_exists "$1"; then
    die "profile not found: $1"
  fi
}

current_profile() {
  if [ ! -f "$MARIONETTE_CURRENT_PROFILE_FILE" ]; then
    return 1
  fi
  sed -n '1p' "$MARIONETTE_CURRENT_PROFILE_FILE"
}

current_profile_or_die() {
  current_profile || die "no active profile"
}

set_current_profile() {
  printf '%s\n' "$1" >"$MARIONETTE_CURRENT_PROFILE_FILE"
}

clear_current_profile() {
  rm -f "$MARIONETTE_CURRENT_PROFILE_FILE"
}

clear_current_profile_if_selected() {
  local current
  local profile
  profile=$1
  current=$(current_profile) || return 0
  if [ "$current" = "$profile" ]; then
    clear_current_profile
  fi
}

list_profiles() {
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

create_profile() {
  local name
  name=$1
  mkdir -p "$(profile_dir "$name")"
  : >"$(profile_hosts_file "$name")"
}

remove_profile() {
  rm -rf "$(profile_dir "$1")"
}
