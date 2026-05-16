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

require_host() {
  local profile
  local alias
  profile=$1
  alias=$2
  if ! host_exists "$profile" "$alias"; then
    output_die "host not found: $alias"
  fi
}

each_host() {
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

add_host() {
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

remove_host() {
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

write_ssh_config_host() {
  local alias
  local user
  local hostname
  local output
  local known_hosts
  alias=$1
  user=$2
  hostname=$3
  output=$4
  known_hosts=$5
  cat >>"$output" <<EOF
Host $alias
  HostName $hostname
  User $user
  UserKnownHostsFile $known_hosts

EOF
}

write_ssh_config() {
  local profile
  local output
  local known_hosts
  profile=$1
  output=$2
  known_hosts=$(profile_known_hosts_file "$profile")
  : >"$output"
  : >"$known_hosts"
  each_host "$profile" write_ssh_config_host "$output" "$known_hosts"
}

run_host_alias() {
  local alias
  local profile
  alias=$1
  shift
  profile=$(profile_current_or_die)
  profile_require "$profile"
  require_host "$profile" "$alias"
  write_ssh_config "$profile" "$MARIONETTE_GENERATED_CONFIG_FILE"
  exec ssh -F "$MARIONETTE_GENERATED_CONFIG_FILE" "$alias" "$@"
}
