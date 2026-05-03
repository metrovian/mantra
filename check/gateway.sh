check_gateway() {
  local latency
  local latency_ms
  local start_ms
  local end_ms
  local mac
  local company
  local hostname
  start_ms="$(dns_now_ms)"
  if inspect_host_reachable "$GATEWAY" >/dev/null 2>&1; then
    end_ms="$(dns_now_ms)"
    latency_ms="$((end_ms - start_ms))"
    latency="${latency_ms} ms"
  else
    latency="-"
  fi
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
