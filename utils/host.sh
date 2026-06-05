host_exists() {
  local profile
  local alias
  local hosts_file
  profile=$1
  alias=$2
  hosts_file=$(profile_hosts_file "$profile")
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
  hosts_file=$(profile_hosts_file "$profile")
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
  hosts_file=$(profile_hosts_file "$profile")
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
  hosts_file=$(profile_hosts_file "$profile")
  printf '%s %s %s %s\n' \
    "$alias" \
    "$user" \
    "$hostname" \
    "$fingerprint" \
    >>"$hosts_file"
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
  known_hosts_file=$(profile_known_hosts_file "$profile")
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
  filesystem_replace_if_changed "$known_hosts_file" "$output"
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
  hosts_file=$(profile_hosts_file "$profile")
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
  filesystem_replace_if_changed "$hosts_file" "$output"
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
  hosts_file=$(profile_hosts_file "$profile")
  known_hosts=$(profile_known_hosts_file "$profile")
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

host_record_known_host() {
  local profile
  local key
  local known_hosts
  profile=$1
  key=$2
  known_hosts=$(profile_known_hosts_file "$profile")
  if grep -Fqx "$key" "$known_hosts" 2>/dev/null; then
    return 0
  fi
  printf '%s\n' "$key" >>"$known_hosts"
}

host_prepare_connection() {
  local profile
  local hostname
  local key
  local fingerprint
  profile=$1
  hostname=$2
  key=$(ssh_capture_key "$hostname") || return 1
  fingerprint=$(ssh_fingerprint_from_key "$key") || return 1
  [ -n "$fingerprint" ] || return 1
  host_record_known_host "$profile" "$key"
  printf '%s\n' "$fingerprint"
}

host_run_alias() {
  local alias
  local profile
  alias=$1
  shift
  profile=$(profile_current) || return 1
  profile_require "$profile" || return 1
  if ! host_exists "$profile" "$alias"; then
    return 1
  fi
  host_write_ssh_config "$profile" "$MANTRA_GENERATED_CONFIG_FILE"
  exec ssh -F "$MANTRA_GENERATED_CONFIG_FILE" "$alias" "$@"
}
