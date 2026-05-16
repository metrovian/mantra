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
  local hostname
  profile=$1
  alias=$2
  hostname=$3
  printf '%s\t%s\n' "$alias" "$hostname" >>"$(profile_hosts_file "$profile")"
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
