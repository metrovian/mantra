host_exists() {
  local profile
  local alias
  profile=$1
  alias=$2
  if [ ! -f "$(profile_hosts_file "$profile")" ]; then
    return 1
  fi
  awk -F '\t' -v alias="$alias" '$1 == alias { found = 1 } END { exit !found }' \
    "$(profile_hosts_file "$profile")"
}

host_each() {
  local profile
  local callback
  local alias
  local user
  local hostname
  local fingerprint
  profile=$1
  callback=$2
  shift 2
  if [ ! -f "$(profile_hosts_file "$profile")" ]; then
    return 0
  fi
  while IFS=$'\t' read -r alias user hostname fingerprint; do
    [ -n "$alias" ] || continue
    "$callback" "$alias" "$user" "$hostname" "$fingerprint" "$@"
  done <"$(profile_hosts_file "$profile")"
}

host_count() {
  local profile
  profile=$1
  if [ ! -f "$(profile_hosts_file "$profile")" ]; then
    printf '0\n'
    return 0
  fi
  awk -F '\t' 'NF > 0 && $1 != "" { count++ } END { print count + 0 }' \
    "$(profile_hosts_file "$profile")"
}

host_add() {
  local profile
  local alias
  local user
  local hostname
  local fingerprint
  profile=$1
  alias=$2
  user=$3
  hostname=$4
  fingerprint=${5:-}
  printf '%s\t%s\t%s\t%s\n' \
    "$alias" \
    "$user" \
    "$hostname" \
    "$fingerprint" \
    >>"$(profile_hosts_file "$profile")"
}

host_remove() {
  local profile
  local alias
  local input
  local output
  profile=$1
  alias=$2
  input=$(profile_hosts_file "$profile")
  output=$input.tmp
  awk -F '\t' -v alias="$alias" '$1 != alias { print }' "$input" >"$output"
  mv "$output" "$input"
}

host_write_ssh_config() {
  local profile
  local output
  local known_hosts
  local alias
  local user
  local hostname
  profile=$1
  output=$2
  known_hosts=$(profile_known_hosts_file "$profile")
  if [ ! -f "$known_hosts" ]; then
    : >"$known_hosts"
  fi
  : >"$output"
  while IFS=$'\t' read -r alias user hostname _; do
    [ -n "$alias" ] || continue
    cat >>"$output" <<EOF2
Host $alias
  HostName $hostname
  User $user
  UserKnownHostsFile $known_hosts

EOF2
  done <"$(profile_hosts_file "$profile")"
}

host_capture_ssh_key() {
  local hostname
  local output
  hostname=$1
  output="$(ssh-keyscan -T 2 -t ed25519 "$hostname" 2>/dev/null || true)"
  if [ -n "$output" ]; then
    printf '%s\n' "$output"
    return 0
  fi
  output="$(ssh-keyscan -T 2 "$hostname" 2>/dev/null || true)"
  if [ -n "$output" ]; then
    printf '%s\n' "$output"
    return 0
  fi
  return 1
}

host_ssh_fingerprint() {
  local hostname
  local output
  hostname=$1
  output="$({ ssh-keyscan -T 2 -t ed25519 "$hostname" 2>/dev/null || true; } \
    | ssh-keygen -lf - -E sha256 2>/dev/null \
    | awk 'NR == 1 { print "ed25519:" $2 }'
  )"
  if [ -n "$output" ]; then
    printf '%s\n' "$output"
    return 0
  fi
  output="$({ ssh-keyscan -T 2 "$hostname" 2>/dev/null || true; } \
    | ssh-keygen -lf - -E sha256 2>/dev/null \
    | awk 'NR == 1 {
        type = $NF
        gsub(/^\(/, "", type)
        gsub(/\)$/, "", type)
        print tolower(type) ":" $2
      }'
  )"
  printf '%s\n' "$output"
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
  key=$(host_capture_ssh_key "$hostname") || return 1
  fingerprint=$(host_ssh_fingerprint "$hostname")
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
  host_write_ssh_config "$profile" "$MARIONETTE_GENERATED_CONFIG_FILE"
  exec ssh -F "$MARIONETTE_GENERATED_CONFIG_FILE" "$alias" "$@"
}
