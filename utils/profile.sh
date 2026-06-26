profile_prepare() {
  MANTRA_HOME=${MANTRA_HOME:-"$HOME/.config/mantra"}
  MANTRA_PROFILES_DIR=$MANTRA_HOME/profiles
  MANTRA_STATE_DIR=$MANTRA_HOME/state
  MANTRA_CURRENT_PROFILE_FILE=$MANTRA_STATE_DIR/current_profile
  MANTRA_GENERATED_CONFIG_FILE=$MANTRA_STATE_DIR/ssh_config
  mkdir -p "$MANTRA_PROFILES_DIR" "$MANTRA_STATE_DIR"
  profile_add "$(profile_default)"
  profile_migrate_current
}

profile_default() {
  printf 'default\n'
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

profile_migrate_current() {
  local current
  local default
  local default_hosts
  current=
  default=$(profile_default)
  default_hosts=$(profile_path "$default" hosts)
  [ -s "$default_hosts" ] && return 0
  [ -f "$MANTRA_CURRENT_PROFILE_FILE" ] || return 0
  current=$(sed -n '1p' "$MANTRA_CURRENT_PROFILE_FILE")
  [ -n "$current" ] || return 0
  [ "$current" = "$default" ] && return 0
  [ -f "$(profile_path "$current" hosts)" ] || return 0
  cp "$(profile_path "$current" hosts)" "$default_hosts"
  if [ -f "$(profile_path "$current" known_hosts)" ]; then
    cp "$(profile_path "$current" known_hosts)" "$(profile_path "$default" known_hosts)"
  fi
}

profile_add() {
  local name
  name=$1
  mkdir -p "$(profile_dir "$name")"
  [ -f "$(profile_path "$name" hosts)" ] || : >"$(profile_path "$name" hosts)"
  [ -f "$(profile_path "$name" known_hosts)" ] || : >"$(profile_path "$name" known_hosts)"
}
