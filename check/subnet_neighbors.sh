check_subnet_neighbors() {
  local ip
  local mac
  local company
  local hostname

  table_reset
  table_set_headers "IP" "MAC" "company" "hostname"

  while IFS= read -r ip; do
    inspect_host "$ip" &
  done < <(network_subnet_hosts)

  wait

  while IFS= read -r ip; do
    mac="$(lookup_mac "$ip")"

    if [[ -n "${mac:-}" && "$mac" != "(incomplete)" ]]; then
      company="$(lookup_company "$mac")"
      hostname="$(resolve_hostname "$ip")"
      table_add_row "$ip" "$mac" "${company:--}" "${hostname:--}"
    fi
  done < <(network_subnet_hosts)

  table_print
}
