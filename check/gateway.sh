check_gateway() {
  local latency
  local mac
  local company
  local hostname
  latency="$(gateway_ping_latency "$GATEWAY")"
  mac="$(lookup_mac "$GATEWAY")"
  company="-"
  [[ -n "${mac:-}" && "$mac" != "(incomplete)" ]] && company="$(lookup_company "$mac")"
  hostname="$(resolve_hostname "$GATEWAY")"
  pair_reset
  pair_set_title "GATEWAY"
  pair_add "latency" "$latency"
  pair_add "ip" "$GATEWAY"
  pair_add "mac" "${mac:--}"
  pair_add "company" "${company:--}"
  pair_add "hostname" "${hostname:--}"
  pair_print
}

gateway_ping_latency() {
  local ping_output
  ping_output="$(inspect_host_reachable "$1" 2>/dev/null || true)"
  awk -F'time=' 'NF > 1 {split($2, parts, /[[:space:]]|ms/); printf "%.0f ms\n", parts[1]; exit}' <<<"$ping_output"
}
