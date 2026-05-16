#!/usr/bin/env bash

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

host_record() {
  local profile
  local alias
  profile=$1
  alias=$2
  if [ ! -f "$(profile_hosts_file "$profile")" ]; then
    return 1
  fi
  awk -F '\t' -v alias="$alias" '$1 == alias { print; found = 1 } END { exit !found }' \
    "$(profile_hosts_file "$profile")"
}

list_hosts() {
  local profile
  profile=$1
  if [ -f "$(profile_hosts_file "$profile")" ]; then
    cat "$(profile_hosts_file "$profile")"
  fi
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

write_ssh_config() {
  local profile
  local output
  local alias
  local user
  local hostname
  profile=$1
  output=$2
  : >"$output"
  while IFS=$'\t' read -r alias user hostname; do
    [ -n "$alias" ] || continue
    cat >>"$output" <<EOF
Host $alias
  HostName $hostname
  User $user

EOF
  done <<EOF
$(list_hosts "$profile")
EOF
}

run_host_alias() {
  local alias
  local profile
  alias=$1
  shift
  profile=$(current_profile) || die "no active profile"
  if ! profile_exists "$profile"; then
    die "profile not found: $profile"
  fi
  if ! host_exists "$profile" "$alias"; then
    die "host not found in current profile: $alias"
  fi
  write_ssh_config "$profile" "$MARIONETTE_GENERATED_CONFIG_FILE"
  exec ssh -F "$MARIONETTE_GENERATED_CONFIG_FILE" "$alias" "$@"
}
