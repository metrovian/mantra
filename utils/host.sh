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
  profile=$1
  callback=$2
  shift 2
  if [ ! -f "$(profile_hosts_file "$profile")" ]; then
    return 0
  fi
  while IFS=$'\t' read -r alias user hostname; do
    [ -n "$alias" ] || continue
    "$callback" "$alias" "$user" "$hostname" "$@"
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
  profile=$1
  alias=$2
  user=$3
  hostname=$4
  printf '%s\t%s\t%s\n' "$alias" "$user" "$hostname" >>"$(profile_hosts_file "$profile")"
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
  while IFS=$'\t' read -r alias user hostname; do
    [ -n "$alias" ] || continue
    cat >>"$output" <<EOF
Host $alias
  HostName $hostname
  User $user
  UserKnownHostsFile $known_hosts

EOF
  done <"$(profile_hosts_file "$profile")"
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
