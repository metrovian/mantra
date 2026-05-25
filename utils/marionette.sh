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

marionette_known_host_fingerprint() {
  local line
  local output
  line=${1:-}
  [[ -n "$line" ]] || return 1
  output="$(printf '%s\n' "$line" \
    | ssh-keygen -lf - -E sha256 2>/dev/null \
    | awk 'NR == 1 {
        type = $NF
        gsub(/^\(/, "", type)
        gsub(/\)$/, "", type)
        print tolower(type) ":" $2
      }'
  )"
  [[ -n "$output" ]] || return 1
  printf '%s\n' "$output"
}

marionette_write_fingerprint_map() {
  local records
  local map_file
  records=${1:-}
  map_file=$2
  awk -F '\t' -v OFS='\t' '
    $1 != "" && $2 != "" && $2 != "-" {
      print $2, $1
    }
  ' <(printf '%s\n' "$records") >"$map_file"
}

marionette_write_hosts_file() {
  local map_file
  local hosts_file
  local output_file
  map_file=$1
  hosts_file=$2
  [[ -f "$hosts_file" ]] || return 0
  output_file=$(mktemp "${TMPDIR:-/tmp}/radiance.XXXXXX")
  awk -F '\t' -v OFS='\t' '
    NR == FNR {
      if ($1 != "" && $2 != "") {
        by_fingerprint[$1] = $2
      }
      next
    }
    ($4 in by_fingerprint) {
      $3 = by_fingerprint[$4]
    }
    {
      print
    }
  ' "$map_file" "$hosts_file" >"$output_file"
  marionette_replace_file "$hosts_file" "$output_file"
}

marionette_write_known_hosts_file() {
  local map_file
  local known_hosts_file
  local output_file
  local line
  local fingerprint
  local ip
  local key
  map_file=$1
  known_hosts_file=$2
  [[ -f "$known_hosts_file" ]] || return 0
  output_file=$(mktemp "${TMPDIR:-/tmp}/radiance.XXXXXX")
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ -z "$line" || "$line" == \#* ]]; then
      printf '%s\n' "$line"
      continue
    fi
    fingerprint=$(marionette_known_host_fingerprint "$line" || true)
    if [[ -z "$fingerprint" ]]; then
      printf '%s\n' "$line"
      continue
    fi
    ip=$(awk -F '\t' -v fingerprint="$fingerprint" '
      $1 == fingerprint {
        print $2
        exit
      }
    ' "$map_file")
    if [[ -z "$ip" ]]; then
      printf '%s\n' "$line"
      continue
    fi
    key=${line#* }
    printf '%s %s\n' "$ip" "$key"
  done <"$known_hosts_file" >"$output_file"
  marionette_replace_file "$known_hosts_file" "$output_file"
}

marionette_sync_profile() {
  local map_file
  local profile_dir
  local hosts_file
  local known_hosts_file
  map_file=$1
  profile_dir=$2
  hosts_file=$profile_dir/hosts
  known_hosts_file=$profile_dir/known_hosts
  marionette_write_hosts_file "$map_file" "$hosts_file"
  marionette_write_known_hosts_file "$map_file" "$known_hosts_file"
}

marionette_sync() {
  local records
  local home_dir
  local profiles_dir
  local state_dir
  local profile_dir
  local map_file
  records=${1:-}
  [[ -n "$records" ]] || return 0
  home_dir=${MARIONETTE_HOME:-"$HOME/.config/marionette"}
  [[ -d "$home_dir" ]] || return 0
  profiles_dir=$home_dir/profiles
  state_dir=$home_dir/state
  mkdir -p "$profiles_dir" "$state_dir"
  map_file=$(mktemp "${TMPDIR:-/tmp}/radiance.XXXXXX")
  marionette_write_fingerprint_map "$records" "$map_file"
  for profile_dir in "$profiles_dir"/*; do
    [[ -d "$profile_dir" ]] || continue
    marionette_sync_profile "$map_file" "$profile_dir"
  done
  rm -f "$map_file"
}
