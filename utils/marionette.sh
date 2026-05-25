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

marionette_write_hosts_file() {
  local records_file
  local hosts_file
  local output_file
  records_file=$1
  hosts_file=$2
  [[ -f "$hosts_file" ]] || return 0
  output_file=$(mktemp "${TMPDIR:-/tmp}/radiance.XXXXXX")
  awk -F '\t' -v OFS='\t' '
    NR == FNR {
      if ($1 != "" && $2 != "" && $2 != "-") {
        by_fingerprint[$2] = $1
      }
      next
    }
    ($4 in by_fingerprint) {
      $3 = by_fingerprint[$4]
    }
    {
      print
    }
  ' "$records_file" "$hosts_file" >"$output_file"
  marionette_replace_file "$hosts_file" "$output_file"
}

marionette_write_known_hosts_file() {
  local records_file
  local known_hosts_file
  local output_file
  records_file=$1
  known_hosts_file=$2
  [[ -f "$known_hosts_file" ]] || return 0
  output_file=$(mktemp "${TMPDIR:-/tmp}/radiance.XXXXXX")
  awk -F '\t' '
    NR == FNR {
      if ($1 != "" && $3 != "" && $3 != "-") {
        by_key[$3] = $1
      }
      next
    }
    /^[[:space:]]*$/ || /^#/ {
      print
      next
    }
    {
      key = $0
      sub(/^[^ ]+ /, "", key)
      if (key in by_key) {
        sub(/^[^ ]+/, by_key[key])
      }
      print
    }
  ' "$records_file" "$known_hosts_file" >"$output_file"
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
