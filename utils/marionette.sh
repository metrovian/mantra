marionette_record_host_for() {
  local records
  local field
  local value
  records=${1:-}
  field=$2
  value=$3
  awk -F '\t' -v field="$field" -v value="$value" '
    $1 != "" && $field == value {
      print $1
      exit
    }
  ' <<<"$records"
}

marionette_write_hosts_file() {
  local records
  local hosts_file
  local output_file
  local alias
  local user
  local hostname
  local fingerprint
  local matched_host
  records=${1:-}
  hosts_file=$2
  [[ -f "$hosts_file" ]] || return 0
  output_file=$(mktemp "${TMPDIR:-/tmp}/marionette.XXXXXX")
  while IFS=' ' read -r alias user hostname fingerprint; do
    if [[ -z "$alias" ]]; then
      printf '\n'
      continue
    fi
    matched_host=
    if [[ -n "$fingerprint" && "$fingerprint" != "-" ]]; then
      matched_host=$(marionette_record_host_for "$records" 2 "$fingerprint")
    fi
    if [[ -n "$matched_host" ]]; then
      hostname=$matched_host
    fi
    printf '%s %s %s %s\n' "$alias" "$user" "$hostname" "$fingerprint"
  done <"$hosts_file" >"$output_file"
  filesystem_replace_if_changed "$hosts_file" "$output_file"
}

marionette_write_known_hosts_file() {
  local records
  local known_hosts_file
  local output_file
  local line
  local host_field
  local key
  local matched_host
  records=${1:-}
  known_hosts_file=$2
  [[ -f "$known_hosts_file" ]] || return 0
  output_file=$(mktemp "${TMPDIR:-/tmp}/marionette.XXXXXX")
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
    matched_host=$(marionette_record_host_for "$records" 3 "$key")
    if [[ -n "$matched_host" ]]; then
      host_field=$matched_host
    fi
    printf '%s %s\n' "$host_field" "$key"
  done <"$known_hosts_file" >"$output_file"
  filesystem_replace_if_changed "$known_hosts_file" "$output_file"
}

marionette_sync_profile() {
  local records
  local profile_dir
  local hosts_file
  local known_hosts_file
  records=${1:-}
  profile_dir=$2
  hosts_file=$profile_dir/hosts
  known_hosts_file=$profile_dir/known_hosts
  marionette_write_hosts_file "$records" "$hosts_file"
  marionette_write_known_hosts_file "$records" "$known_hosts_file"
}

marionette_sync() {
  local records
  local home_dir
  local profiles_dir
  local profile_dir
  records=${1:-}
  [[ -n "$records" ]] || return 0
  home_dir=${MARIONETTE_HOME:-"$HOME/.config/marionette"}
  [[ -d "$home_dir" ]] || return 0
  profiles_dir=$home_dir/profiles
  mkdir -p "$profiles_dir"
  for profile_dir in "$profiles_dir"/*; do
    [[ -d "$profile_dir" ]] || continue
    marionette_sync_profile "$records" "$profile_dir"
  done
}
