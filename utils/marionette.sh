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

marionette_record_host_for() {
  local field
  local value
  local records_file
  field=$1
  value=$2
  records_file=$3
  awk -F '\t' -v field="$field" -v value="$value" '
    $1 != "" && $field == value {
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
      matched_host=$(marionette_record_host_for 2 "$fingerprint" "$records_file")
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
  local matched_host
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
    matched_host=$(marionette_record_host_for 3 "$key" "$records_file")
    if [[ -n "$matched_host" ]]; then
      host_field=$matched_host
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
  local profile_dir
  local records_file
  records=${1:-}
  [[ -n "$records" ]] || return 0
  home_dir=${MARIONETTE_HOME:-"$HOME/.config/marionette"}
  [[ -d "$home_dir" ]] || return 0
  profiles_dir=$home_dir/profiles
  mkdir -p "$profiles_dir"
  records_file=$(mktemp "${TMPDIR:-/tmp}/radiance.XXXXXX")
  printf '%s\n' "$records" >"$records_file"
  for profile_dir in "$profiles_dir"/*; do
    [[ -d "$profile_dir" ]] || continue
    marionette_sync_profile "$records_file" "$profile_dir"
  done
  rm -f "$records_file"
}
