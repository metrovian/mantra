host_exists() {
  local profile
  local alias
  local hosts_file
  profile=$1
  alias=$2
  hosts_file=$(profile_path "$profile" hosts)
  if [ ! -f "$hosts_file" ]; then
    return 1
  fi
  awk -F '[ ]+' -v alias="$alias" \
    '$1 == alias { found = 1 } END { exit !found }' "$hosts_file"
}

host_each() {
  local profile
  local callback
  local hosts_file
  local alias
  local user
  local hostname
  local fingerprint
  profile=$1
  callback=$2
  shift 2
  hosts_file=$(profile_path "$profile" hosts)
  if [ ! -f "$hosts_file" ]; then
    return 0
  fi
  while IFS=' ' read -r alias user hostname fingerprint; do
    [ -n "$alias" ] || continue
    "$callback" "$alias" "$user" "$hostname" "$fingerprint" "$@"
  done <"$hosts_file"
}

host_count() {
  local profile
  local hosts_file
  profile=$1
  hosts_file=$(profile_path "$profile" hosts)
  if [ ! -f "$hosts_file" ]; then
    printf '0\n'
    return 0
  fi
  awk -F '[ ]+' \
    'NF > 0 && $1 != "" { count++ } END { print count + 0 }' "$hosts_file"
}

host_add() {
  local profile
  local alias
  local user
  local hostname
  local fingerprint
  local hosts_file
  profile=$1
  alias=$2
  user=$3
  hostname=$4
  fingerprint=${5:-}
  hosts_file=$(profile_path "$profile" hosts)
  printf '%s %s %s %s\n' \
    "$alias" \
    "$user" \
    "$hostname" \
    "$fingerprint" \
    >>"$hosts_file"
}

host_replace() {
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

host_record_for() {
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

host_write_hosts_file() {
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
  [ -f "$hosts_file" ] || return 0
  output_file=$(mktemp "${TMPDIR:-/tmp}/mantra.XXXXXX")
  while IFS=' ' read -r alias user hostname fingerprint; do
    if [ -z "$alias" ]; then
      printf '\n'
      continue
    fi
    matched_host=
    if [ -n "$fingerprint" ] && [ "$fingerprint" != "-" ]; then
      matched_host=$(host_record_for "$records" 2 "$fingerprint")
    fi
    if [ -n "$matched_host" ]; then
      hostname=$matched_host
    fi
    printf '%s %s %s %s\n' "$alias" "$user" "$hostname" "$fingerprint"
  done <"$hosts_file" >"$output_file"
  host_replace "$hosts_file" "$output_file"
}

host_write_known_hosts_file() {
  local records
  local known_hosts_file
  local output_file
  local line
  local host_field
  local key
  local matched_host
  records=${1:-}
  known_hosts_file=$2
  [ -f "$known_hosts_file" ] || return 0
  output_file=$(mktemp "${TMPDIR:-/tmp}/mantra.XXXXXX")
  while IFS= read -r line; do
    if [ -z "$line" ] || [ "${line#\#}" != "$line" ]; then
      printf '%s\n' "$line"
      continue
    fi
    host_field=${line%% *}
    key=${line#* }
    if [ "$host_field" = "$line" ]; then
      printf '%s\n' "$line"
      continue
    fi
    matched_host=$(host_record_for "$records" 3 "$key")
    if [ -n "$matched_host" ]; then
      host_field=$matched_host
    fi
    printf '%s %s\n' "$host_field" "$key"
  done <"$known_hosts_file" >"$output_file"
  host_replace "$known_hosts_file" "$output_file"
}

host_sync() {
  local records
  local profile_dir
  local hosts_file
  local known_hosts_file
  records=${1:-}
  [ -n "$records" ] || return 0
  [ -d "$MANTRA_HOME" ] || return 0
  for profile_dir in "$MANTRA_PROFILES_DIR"/*; do
    [ -d "$profile_dir" ] || continue
    hosts_file=$profile_dir/hosts
    known_hosts_file=$profile_dir/known_hosts
    host_write_hosts_file "$records" "$hosts_file"
    host_write_known_hosts_file "$records" "$known_hosts_file"
  done
}

host_remove_known_host_by_fingerprint() {
  local profile
  local fingerprint
  local known_hosts_file
  local output
  local line
  local line_fingerprint
  profile=$1
  fingerprint=$2
  [ -n "$fingerprint" ] || return 0
  known_hosts_file=$(profile_path "$profile" known_hosts)
  [ -f "$known_hosts_file" ] || return 0
  output=$(mktemp "${TMPDIR:-/tmp}/mantra.XXXXXX")
  while IFS= read -r line; do
    if [ -z "$line" ] || [ "${line#\#}" != "$line" ]; then
      printf '%s\n' "$line" >>"$output"
      continue
    fi
    line_fingerprint=$(ssh_fingerprint_from_key "$line" || true)
    if [ "$line_fingerprint" = "$fingerprint" ]; then
      continue
    fi
    printf '%s\n' "$line" >>"$output"
  done <"$known_hosts_file"
  host_replace "$known_hosts_file" "$output"
}

host_remove() {
  local profile
  local alias
  local hosts_file
  local output
  local host_alias
  local user
  local hostname
  local fingerprint
  local removed_fingerprint
  profile=$1
  alias=$2
  hosts_file=$(profile_path "$profile" hosts)
  output=$(mktemp "${TMPDIR:-/tmp}/mantra.XXXXXX")
  removed_fingerprint=
  while IFS=' ' read -r host_alias user hostname fingerprint; do
    if [ -z "$host_alias" ]; then
      printf '\n' >>"$output"
      continue
    fi
    if [ "$host_alias" = "$alias" ]; then
      removed_fingerprint=$fingerprint
      continue
    fi
    printf '%s %s %s %s\n' \
      "$host_alias" \
      "$user" \
      "$hostname" \
      "$fingerprint" \
      >>"$output"
  done <"$hosts_file"
  host_replace "$hosts_file" "$output"
  host_remove_known_host_by_fingerprint "$profile" "$removed_fingerprint"
}

host_write_ssh_config() {
  local profile
  local output
  local hosts_file
  local known_hosts
  local alias
  local user
  local hostname
  profile=$1
  output=$2
  hosts_file=$(profile_path "$profile" hosts)
  known_hosts=$(profile_path "$profile" known_hosts)
  if [ ! -f "$known_hosts" ]; then
    : >"$known_hosts"
  fi
  : >"$output"
  while IFS=' ' read -r alias user hostname _; do
    [ -n "$alias" ] || continue
    cat >>"$output" <<EOF2
Host $alias
  HostName $hostname
  User $user
  UserKnownHostsFile $known_hosts

EOF2
  done <"$hosts_file"
}

host_prepare_connection() {
  local profile
  local hostname
  local key
  local fingerprint
  local known_hosts
  profile=$1
  hostname=$2
  key=$(ssh_capture_key "$hostname") || return 1
  fingerprint=$(ssh_fingerprint_from_key "$key") || return 1
  [ -n "$fingerprint" ] || return 1
  known_hosts=$(profile_path "$profile" known_hosts)
  if ! grep -Fqx "$key" "$known_hosts" 2>/dev/null; then
    printf '%s\n' "$key" >>"$known_hosts"
  fi
  printf '%s\n' "$fingerprint"
}
