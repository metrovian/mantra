marionette_sync() {
  local records
  local home_dir
  local profiles_dir
  local state_dir
  local neighbors_file
  local profile_dir
  local profile
  local hosts_file
  local output_file
  local count_file
  local updated
  local updated_profiles
  local updated_hosts
  records=${1:-}
  [[ -n "$records" ]] || return 0
  home_dir=${MARIONETTE_HOME:-"$HOME/.config/marionette"}
  [[ -d "$home_dir" ]] || return 0
  profiles_dir=$home_dir/profiles
  state_dir=$home_dir/state
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
  if [[ "$updated_hosts" -gt 0 ]]; then
    printf 'marionette synced %s host%s across %s profile%s\n' \
      "$updated_hosts" \
      "$( [[ "$updated_hosts" -eq 1 ]] && printf '' || printf 's' )" \
      "$updated_profiles" \
      "$( [[ "$updated_profiles" -eq 1 ]] && printf '' || printf 's' )"
  fi
}
