marionette_replace_file() {
  local target_file
  local output_file
  target_file=$1
  output_file=$2
  if cmp -s "$target_file" "$output_file"; then
    rm -f "$output_file"
  else
    mv "$output_file" "$target_file"
  fi
}

marionette_write_records_file() {
  local records
  local records_file
  records=${1:-}
  records_file=$2
  printf '%s\n' "$records" >"$records_file"
}

marionette_host_for_fingerprint() {
  local fingerprint
  local records_file
  fingerprint=$1
  records_file=$2
  awk -F '\t' -v fingerprint="$fingerprint" '
    $1 != "" && $2 == fingerprint {
      print $1
      exit
    }
  ' "$records_file"
}

marionette_alias_for_key() {
  local key
  local records_file
  key=$1
  records_file=$2
  awk -F '\t' -v key="$key" '
    $1 != "" && $3 == key {
      print $1
      exit
    }
  ' "$records_file"
}

marionette_write_hosts_file() {
  local records_file
  local hosts_file
  local output_file
  local alias
  local user
  local hostname
  local fingerprint
  local matched_host
  records_file=$1
  hosts_file=$2
  [[ -f "$hosts_file" ]] || return 0
  output_file=$(mktemp "${TMPDIR:-/tmp}/radiance.XXXXXX")
  while IFS=' ' read -r alias user hostname fingerprint; do
    if [[ -z "$alias" ]]; then
      printf '\n'
      continue
    fi
    matched_host=
    if [[ -n "$fingerprint" && "$fingerprint" != "-" ]]; then
      matched_host=$(marionette_host_for_fingerprint "$fingerprint" "$records_file")
    fi
    if [[ -n "$matched_host" ]]; then
      hostname=$matched_host
    fi
    printf '%s %s %s %s\n' "$alias" "$user" "$hostname" "$fingerprint"
  done <"$hosts_file" >"$output_file"
  marionette_replace_file "$hosts_file" "$output_file"
}

marionette_write_known_hosts_file() {
  local records_file
  local known_hosts_file
  local output_file
  local line
  local host_field
  local key
  local alias
  records_file=$1
  known_hosts_file=$2
  [[ -f "$known_hosts_file" ]] || return 0
  output_file=$(mktemp "${TMPDIR:-/tmp}/radiance.XXXXXX")
  while IFS= read -r line; do
    if [[ -z "$line" || "$line" == \#* ]]; then
      printf '%s\n' "$line"
      continue
    fi
    host_field=${line%% *}
    key=${line#* }
    if [[ "$host_field" == "$line" ]]; then
      printf '%s\n' "$line"
      continue
    fi
    alias=$(marionette_alias_for_key "$key" "$records_file")
    if [[ -n "$alias" ]]; then
      host_field=$alias
    fi
    printf '%s %s\n' "$host_field" "$key"
  done <"$known_hosts_file" >"$output_file"
  marionette_replace_file "$known_hosts_file" "$output_file"
}

marionette_sync_profile() {
  local records_file
  local profile_dir
  local hosts_file
  local known_hosts_file
  records_file=$1
  profile_dir=$2
  hosts_file=$profile_dir/hosts
  known_hosts_file=$profile_dir/known_hosts
  marionette_write_hosts_file "$records_file" "$hosts_file"
  marionette_write_known_hosts_file "$records_file" "$known_hosts_file"
}

marionette_sync() {
  local records
  local home_dir
  local profiles_dir
  local state_dir
  local profile_dir
  local records_file
  records=${1:-}
  [[ -n "$records" ]] || return 0
  home_dir=${MARIONETTE_HOME:-"$HOME/.config/marionette"}
  [[ -d "$home_dir" ]] || return 0
  profiles_dir=$home_dir/profiles
  state_dir=$home_dir/state
  mkdir -p "$profiles_dir" "$state_dir"
  records_file=$(mktemp "${TMPDIR:-/tmp}/radiance.XXXXXX")
  marionette_write_records_file "$records" "$records_file"
  for profile_dir in "$profiles_dir"/*; do
    [[ -d "$profile_dir" ]] || continue
    marionette_sync_profile "$records_file" "$profile_dir"
  done
  rm -f "$records_file"
}
