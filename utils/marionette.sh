marionette_write_ssh_config() {
  local hosts_file
  local known_hosts
  local output
  local alias
  local user
  local hostname
  hosts_file=$1
  known_hosts=$2
  output=$3
  [[ -f "$hosts_file" ]] || return 0
  [[ -f "$known_hosts" ]] || : >"$known_hosts"
  : >"$output"
  while IFS=$'\t' read -r alias user hostname _; do
    [[ -n "$alias" ]] || continue
    cat >>"$output" <<EOF2
Host $alias
  HostName $hostname
  User $user
  UserKnownHostsFile $known_hosts

EOF2
  done <"$hosts_file"
}

marionette_sync() {
  local records
  local home_dir
  local profiles_dir
  local state_dir
  local current_profile_file
  local generated_config_file
  local neighbors_file
  local profile_dir
  local profile
  local hosts_file
  local known_hosts_file
  local output_file
  local count_file
  local current_profile
  local updated
  local updated_profiles
  local updated_hosts
  records=${1:-}
  [[ -n "$records" ]] || return 0
  home_dir=${MARIONETTE_HOME:-"$HOME/.config/marionette"}
  [[ -d "$home_dir" ]] || return 0
  profiles_dir=$home_dir/profiles
  state_dir=$home_dir/state
  current_profile_file=$state_dir/current_profile
  generated_config_file=$state_dir/ssh_config
  mkdir -p "$profiles_dir" "$state_dir"
  neighbors_file=$(mktemp "${TMPDIR:-/tmp}/radiance-marionette-neighbors.XXXXXX")
  printf '%s\n' "$records" >"$neighbors_file"
  updated_profiles=0
  updated_hosts=0
  for profile_dir in "$profiles_dir"/*; do
    [[ -d "$profile_dir" ]] || continue
    profile=$(basename "$profile_dir")
    hosts_file=$profile_dir/hosts
    [[ -f "$hosts_file" ]] || continue
    output_file=$(mktemp "${TMPDIR:-/tmp}/radiance-marionette-hosts.XXXXXX")
    count_file=$(mktemp "${TMPDIR:-/tmp}/radiance-marionette-count.XXXXXX")
    awk -F '\t' -v OFS='\t' -v count_file="$count_file" '
      NR == FNR {
        if ($1 != "" && $2 != "" && $2 != "-") {
          by_fingerprint[$2] = $1
        }
        next
      }
      {
        if (($4 in by_fingerprint) && $3 != by_fingerprint[$4]) {
          $3 = by_fingerprint[$4]
          changed++
        }
        print
      }
      END {
        print changed + 0 > count_file
      }
    ' "$neighbors_file" "$hosts_file" >"$output_file"
    updated=$(sed -n '1p' "$count_file")
    rm -f "$count_file"
    if [[ "${updated:-0}" -gt 0 ]]; then
      mv "$output_file" "$hosts_file"
      updated_profiles=$((updated_profiles + 1))
      updated_hosts=$((updated_hosts + updated))
    else
      rm -f "$output_file"
    fi
  done
  rm -f "$neighbors_file"
  if [[ -f "$current_profile_file" ]]; then
    current_profile=$(sed -n '1p' "$current_profile_file")
    if [[ -n "$current_profile" && -d "$profiles_dir/$current_profile" ]]; then
      marionette_write_ssh_config \
        "$profiles_dir/$current_profile/hosts" \
        "$profiles_dir/$current_profile/known_hosts" \
        "$generated_config_file"
    fi
  fi
  if [[ "$updated_hosts" -gt 0 ]]; then
    printf 'marionette synced %s host%s across %s profile%s\n' \
      "$updated_hosts" \
      "$( [[ "$updated_hosts" -eq 1 ]] && printf '' || printf 's' )" \
      "$updated_profiles" \
      "$( [[ "$updated_profiles" -eq 1 ]] && printf '' || printf 's' )"
  fi
}
