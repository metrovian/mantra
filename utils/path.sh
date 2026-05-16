marionette_init_paths() {
  MARIONETTE_HOME=${MARIONETTE_HOME:-"$HOME/.config/marionette"}
  MARIONETTE_PROFILES_DIR=$MARIONETTE_HOME/profiles
  MARIONETTE_STATE_DIR=$MARIONETTE_HOME/state
  MARIONETTE_CURRENT_PROFILE_FILE=$MARIONETTE_STATE_DIR/current_profile
  MARIONETTE_GENERATED_CONFIG_FILE=$MARIONETTE_STATE_DIR/ssh_config
}

marionette_ensure_layout() {
  mkdir -p "$MARIONETTE_PROFILES_DIR" "$MARIONETTE_STATE_DIR"
}

marionette_prepare() {
  marionette_init_paths
  marionette_ensure_layout
}
