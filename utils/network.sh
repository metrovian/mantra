network_local() {
  local gateway
  local iface
  local me
  local subnet_cidr
  IFS=$'\t' read -r gateway iface me subnet_cidr <<<"$(inspect_network)"
  [[ -n "${gateway:-}" && -n "${iface:-}" && -n "${me:-}" \
    && -n "${subnet_cidr:-}" ]] || return 1
  pair_reset
  pair_set_title "LOCAL"
  pair_add "time" "$(date '+%Y-%m-%d %H:%M:%S %Z')"
  pair_add "iface" "$iface"
  pair_add "me" "$me"
  pair_add "gateway" "$gateway"
  pair_add "subnet" "$subnet_cidr"
  pair_print
}

network_neighbors_records() {
  local ip
  local fingerprint
  local key
  while IFS=$'\t' read -r ip; do
    [[ -n "${ip:-}" ]] || continue
    IFS=$'\t' read -r fingerprint key <<<"$(network_ssh_details "$ip")"
    fingerprint=${fingerprint:--}
    key=${key:--}
    printf '%s\t%s\t%s\n' "$ip" "$fingerprint" "$key"
  done < <(
    network_neighbors_scan "$@" | network_neighbors_parse
  )
}

network_neighbors_print() {
  local ip
  local fingerprint
  local records
  records=${1:-}
  table_reset
  table_set_headers "IP" "SSH"
  while IFS=$'\t' read -r ip fingerprint _; do
    [[ -n "${ip:-}" ]] || continue
    table_add_row "$ip" "$fingerprint"
  done <<<"$records"
  table_print
}

network_neighbors_scan() {
  nmap -sT -Pn -n -p 22 --open "$@" 2>/dev/null
}

network_neighbors_parse() {
  awk '
    /^Nmap scan report for / {
      ip = $NF
      next
    }
    /^22\/tcp[[:space:]]+open[[:space:]]+ssh$/ {
      print ip
      next
    }
  '
}

network_ssh_details() {
  local ip
  local key_line
  local fingerprint
  local key
  ip=$1
  if ! key_line="$(ssh_capture_key "$ip")"; then
    printf '%s\t%s\n' '-' '-'
    return
  fi
  fingerprint="$(ssh_fingerprint_from_key "$key_line" || true)"
  key="${key_line#* }"
  printf '%s\t%s\n' "${fingerprint:--}" "$key"
}
