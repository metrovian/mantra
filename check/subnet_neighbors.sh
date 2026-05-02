check_subnet_neighbors() {
  local total_hosts
  local host_index
  local active_total
  local active_index
  local progress_total
  local progress_current
  local ip
  local mac
  local company
  local hostname
  local -a hosts=()
  local -a active_ips=()
  local -a active_macs=()
  local -a active_companies=()

  while IFS= read -r ip; do
    hosts+=("$ip")
  done < <(network_subnet_hosts)

  total_hosts=${#hosts[@]}
  progress_total=$((total_hosts * 2))
  progress_current=0

  table_reset
  table_set_headers "IP" "MAC" "company" "hostname"

  for ((host_index = 0; host_index < total_hosts; host_index++)); do
    ip="${hosts[$host_index]}"
    inspect_host "$ip" &
    progress_current=$((progress_current + 1))
    check_subnet_neighbors_progress "$progress_current" "$progress_total"
  done

  wait

  for ((host_index = 0; host_index < total_hosts; host_index++)); do
    ip="${hosts[$host_index]}"
    mac="$(lookup_mac "$ip")"
    progress_current=$((progress_current + 1))
    check_subnet_neighbors_progress "$progress_current" "$progress_total"

    if [[ -n "${mac:-}" && "$mac" != "(incomplete)" ]]; then
      company="$(lookup_company "$mac")"
      active_ips+=("$ip")
      active_macs+=("$mac")
      active_companies+=("${company:--}")
    fi
  done

  check_subnet_neighbors_progress_done

  active_total=${#active_ips[@]}
  progress_total=$((progress_total + active_total))

  if ((active_total == 0)); then
    table_print
    return
  fi

  for ((active_index = 0; active_index < active_total; active_index++)); do
    hostname="$(resolve_hostname "${active_ips[$active_index]}")"
    table_add_row \
      "${active_ips[$active_index]}" \
      "${active_macs[$active_index]}" \
      "${active_companies[$active_index]}" \
      "${hostname:--}"
    progress_current=$((progress_current + 1))
    check_subnet_neighbors_progress "$progress_current" "$progress_total"
  done

  check_subnet_neighbors_progress_done

  table_print
}

check_subnet_neighbors_progress() {
  printf "\r%s/%s" "$1" "$2" >&2
}

check_subnet_neighbors_progress_done() {
  printf "\r%*s\r" 32 "" >&2
}
