marionette_path_prepare() {
  MARIONETTE_HOME=${MARIONETTE_HOME:-"$HOME/.config/marionette"}
  MARIONETTE_PROFILES_DIR=$MARIONETTE_HOME/profiles
  MARIONETTE_STATE_DIR=$MARIONETTE_HOME/state
  MARIONETTE_CURRENT_PROFILE_FILE=$MARIONETTE_STATE_DIR/current_profile
  MARIONETTE_GENERATED_CONFIG_FILE=$MARIONETTE_STATE_DIR/ssh_config
  [[ -d "$MARIONETTE_HOME" ]] || return 1
  mkdir -p "$MARIONETTE_PROFILES_DIR" "$MARIONETTE_STATE_DIR"
}

marionette_profile_dir() {
  printf '%s/%s\n' "$MARIONETTE_PROFILES_DIR" "$1"
}

marionette_profile_hosts_file() {
  printf '%s/hosts\n' "$(marionette_profile_dir "$1")"
}

marionette_profile_known_hosts_file() {
  printf '%s/known_hosts\n' "$(marionette_profile_dir "$1")"
}

marionette_profile_current() {
  [[ -f "$MARIONETTE_CURRENT_PROFILE_FILE" ]] || return 1
  sed -n '1p' "$MARIONETTE_CURRENT_PROFILE_FILE"
}

marionette_profile_list() {
  local path
  [[ -d "$MARIONETTE_PROFILES_DIR" ]] || return 0
  for path in "$MARIONETTE_PROFILES_DIR"/*; do
    [[ -d "$path" ]] || continue
    basename "$path"
  done
}

marionette_write_ssh_config() {
  local profile
  local output
  local hosts_file
  local known_hosts
  local alias
  local user
  local hostname
  profile=$1
  output=$2
  hosts_file=$(marionette_profile_hosts_file "$profile")
  known_hosts=$(marionette_profile_known_hosts_file "$profile")
  [[ -f "$hosts_file" ]] || return 0
  [[ -f "$known_hosts" ]] || : >"$known_hosts"
  : >"$output"
  while IFS=$'\t' read -r alias user hostname _; do
    [[ -n "$alias" ]] || continue
    cat >>"$output" <<EOF2
Host $alias
  HostName $hostname
  User $user
  UserKnownHostsFile $known_hosts

EOF2
  done <"$hosts_file"
}

marionette_refresh() {
  local profile
  profile=$(marionette_profile_current) || return 0
  [[ -d "$(marionette_profile_dir "$profile")" ]] || return 0
  marionette_write_ssh_config "$profile" "$MARIONETTE_GENERATED_CONFIG_FILE"
}

marionette_sync() {
  local records
  local neighbors_file
  local profile
  local hosts_file
  local output_file
  local count_file
  local updated
  local updated_profiles
  local updated_hosts
  records=${1:-}
  [[ -n "$records" ]] || return 0
  marionette_path_prepare || return 0
  neighbors_file=$(mktemp "${TMPDIR:-/tmp}/radiance-marionette-neighbors.XXXXXX")
  printf '%s\n' "$records" >"$neighbors_file"
  updated_profiles=0
  updated_hosts=0
  for profile in $(marionette_profile_list); do
    hosts_file=$(marionette_profile_hosts_file "$profile")
    [[ -f "$hosts_file" ]] || continue
    output_file=$(mktemp "${TMPDIR:-/tmp}/radiance-marionette-hosts.XXXXXX")
    count_file=$(mktemp "${TMPDIR:-/tmp}/radiance-marionette-count.XXXXXX")
    awk -F '\t' -v OFS='\t' -v count_file="$count_file" '
      NR == FNR {
        if ($1 != "" && $2 != "" && $2 != "-") {
          by_fingerprint[$2] = $1
        }
        next
      }
      {
        if (($4 in by_fingerprint) && $3 != by_fingerprint[$4]) {
          $3 = by_fingerprint[$4]
          changed++
        }
        print
      }
      END {
        print changed + 0 > count_file
      }
    ' "$neighbors_file" "$hosts_file" >"$output_file"
    updated=$(sed -n '1p' "$count_file")
    rm -f "$count_file"
    if [[ "${updated:-0}" -gt 0 ]]; then
      mv "$output_file" "$hosts_file"
      updated_profiles=$((updated_profiles + 1))
      updated_hosts=$((updated_hosts + updated))
    else
      rm -f "$output_file"
    fi
  done
  rm -f "$neighbors_file"
  marionette_refresh
  if [[ "$updated_hosts" -gt 0 ]]; then
    printf 'marionette synced %s host%s across %s profile%s\n' \
      "$updated_hosts" \
      "$( [[ "$updated_hosts" -eq 1 ]] && printf '' || printf 's' )" \
      "$updated_profiles" \
      "$( [[ "$updated_profiles" -eq 1 ]] && printf '' || printf 's' )"
  fi
}
