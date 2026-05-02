check_subnet_neighbors() {
  table_reset
  table_set_headers "IP" "MAC" "company" "hostname"

  for host in $(seq 1 254); do
    inspect_host "${SUBNET_PREFIX}.${host}" &
  done

  wait

  for host in $(seq 1 254); do
    ip="${SUBNET_PREFIX}.${host}"
    mac="$(lookup_mac "$ip")"

    if [[ -n "${mac:-}" && "$mac" != "(incomplete)" ]]; then
      company="$(lookup_company "$mac")"
      hostname="$(resolve_hostname "$ip")"
      table_add_row "$ip" "$mac" "${company:--}" "${hostname:--}"
    fi
  done

  table_print
}
