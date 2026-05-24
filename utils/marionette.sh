marionette_sync() {
  local records
  local home_dir
  local profiles_dir
  local state_dir
  local profile_dir
  local hosts_file
  local output_file
  records=${1:-}
  [[ -n "$records" ]] || return 0
  home_dir=${MARIONETTE_HOME:-"$HOME/.config/marionette"}
  [[ -d "$home_dir" ]] || return 0
  profiles_dir=$home_dir/profiles
  state_dir=$home_dir/state
  mkdir -p "$profiles_dir" "$state_dir"
  for profile_dir in "$profiles_dir"/*; do
    [[ -d "$profile_dir" ]] || continue
    hosts_file=$profile_dir/hosts
    [[ -f "$hosts_file" ]] || continue
    output_file=$(mktemp "${TMPDIR:-/tmp}/radiance.XXXXXX")
    awk -F '\t' -v OFS='\t' '
      NR == FNR {
        if ($1 != "" && $2 != "" && $2 != "-") {
          by_fingerprint[$2] = $1
        }
        next
      }
      ($4 in by_fingerprint) {
        $3 = by_fingerprint[$4]
      }
      {
        print
      }
    ' <(printf '%s\n' "$records") "$hosts_file" >"$output_file"
    if cmp -s "$hosts_file" "$output_file"; then
      rm -f "$output_file"
    else
      mv "$output_file" "$hosts_file"
    fi
  done
}
