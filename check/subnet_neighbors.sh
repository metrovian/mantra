check_subnet_neighbors() {
  printf "%-15s %-17s %-30s %s\n" \
    "IP" "MAC" "company" "hostname"
  printf "%-15s %-17s %-30s %s\n" \
    "---------------" \
    "-----------------" \
    "------------------------------" \
    "--------------------------------"

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
      printf "%-15s %-17s %-30s %s\n" \
        "$ip" "$mac" "${company:--}" "${hostname:--}"
    fi
  done
}
