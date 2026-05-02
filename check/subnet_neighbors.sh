check_subnet_neighbors() {
  local host_int
  local first_int
  local last_int
  local ip
  local mac
  local company
  local hostname

  table_reset
  table_set_headers "IP" "MAC" "company" "hostname"

  first_int="$(prepare_ip_to_int "$SUBNET_FIRST")"
  last_int="$(prepare_ip_to_int "$SUBNET_LAST")"

  for ((host_int = first_int; host_int <= last_int; host_int++)); do
    inspect_host "$(prepare_int_to_ip "$host_int")" &
  done

  wait

  for ((host_int = first_int; host_int <= last_int; host_int++)); do
    ip="$(prepare_int_to_ip "$host_int")"
    mac="$(lookup_mac "$ip")"

    if [[ -n "${mac:-}" && "$mac" != "(incomplete)" ]]; then
      company="$(lookup_company "$mac")"
      hostname="$(resolve_hostname "$ip")"
      table_add_row "$ip" "$mac" "${company:--}" "${hostname:--}"
    fi
  done

  table_print
}
