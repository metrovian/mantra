check_subnet_neighbors() {
  local -a active_hosts=()
  local -a hosts=()
  local ip
  local mac
  local company
  local hostname
  local total_hosts
  local progress_total
  local progress_current
  local index
  mapfile -t hosts < <(network_subnet_hosts)
  total_hosts=${#hosts[@]}
  progress_total=$((total_hosts * 2))
  progress_current=0
  table_reset
  table_set_headers "IP" "MAC" "company" "hostname"
  for ip in "${hosts[@]}"; do
    inspect_host "$ip" &
    progress_current=$((progress_current + 1))
    check_subnet_neighbors_progress "$progress_current" "$progress_total"
  done
  wait
  for ip in "${hosts[@]}"; do
    mac="$(lookup_mac "$ip")"
    progress_current=$((progress_current + 1))
    check_subnet_neighbors_progress "$progress_current" "$progress_total"
    if [[ -n "${mac:-}" && "$mac" != "(incomplete)" ]]; then
      company="$(lookup_company "$mac")"
      active_hosts+=("$ip"$'\t'"$mac"$'\t'"${company:--}")
    fi
  done
  check_subnet_neighbors_progress_done
  progress_total=$((progress_total + ${#active_hosts[@]}))
  if ((${#active_hosts[@]} == 0)); then
    table_print
    return
  fi
  for ((index = 0; index < ${#active_hosts[@]}; index++)); do
    IFS=$'\t' read -r ip mac company <<<"${active_hosts[$index]}"
    hostname="$(resolve_hostname "$ip")"
    table_add_row \
      "$ip" \
      "$mac" \
      "$company" \
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
