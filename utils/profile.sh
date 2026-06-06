profile_prepare() {
  MANTRA_HOME=${MANTRA_HOME:-"$HOME/.config/mantra"}
  MANTRA_PROFILES_DIR=$MANTRA_HOME/profiles
  MANTRA_STATE_DIR=$MANTRA_HOME/state
  MANTRA_CURRENT_PROFILE_FILE=$MANTRA_STATE_DIR/current_profile
  MANTRA_GENERATED_CONFIG_FILE=$MANTRA_STATE_DIR/ssh_config
  mkdir -p "$MANTRA_PROFILES_DIR" "$MANTRA_STATE_DIR"
}

profile_dir() {
  printf '%s/%s\n' "$MANTRA_PROFILES_DIR" "$1"
}

profile_path() {
  printf '%s/%s\n' "$(profile_dir "$1")" "$2"
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
  : >"$(profile_path "$name" hosts)"
  : >"$(profile_path "$name" known_hosts)"
}

profile_remove() {
  rm -rf "$(profile_dir "$1")"
}
