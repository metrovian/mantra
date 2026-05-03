check_gateway() {
  local reachable
  local mac
  local company
  local hostname
  if inspect_host_reachable "$GATEWAY" >/dev/null 2>&1; then
    reachable="yes"
  else
    reachable="no"
  fi
  mac="$(lookup_mac "$GATEWAY")"
  company="-"
  [[ -n "${mac:-}" && "$mac" != "(incomplete)" ]] && company="$(lookup_company "$mac")"
  hostname="$(resolve_hostname "$GATEWAY")"
  pair_reset
  pair_set_title "GATEWAY"
  pair_add "ip" "$GATEWAY"
  pair_add "reachable" "$reachable"
  pair_add "mac" "${mac:--}"
  pair_add "company" "${company:--}"
  pair_add "hostname" "${hostname:--}"
  pair_print
}
