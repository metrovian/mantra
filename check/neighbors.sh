check_neighbors() {
  local -a active_hosts=()
  local -a hosts=()
  local -a mac_ips=()
  local -a mac_values=()
  local -a ping_ips=()
  local -a ping_results=()
  local -a ping_latencies=()
  local ip
  local latency
  local mac
  local hostname
  local total_hosts
  local progress_total
  local progress_current
  local index
  local line
  local mac_index
  local ping_index
  local ping_result
  while IFS= read -r line; do
    if [[ "$line" != "$ME" ]]; then
      hosts+=("$line")
    fi
  done < <(network_subnet_hosts)
  total_hosts=${#hosts[@]}
  progress_total=$((total_hosts + 1))
  progress_current=0
  table_reset
  table_set_headers "IP" "MAC" "hostname" "latency"
  while IFS=$'\t' read -r ip ping_result latency; do
    ping_ips+=("$ip")
    ping_results+=("$ping_result")
    ping_latencies+=("$latency")
    progress_current=$((progress_current + 1))
    check_neighbors_progress "$progress_current" "$progress_total"
  done < <(check_neighbor_ping_table "${hosts[@]}")
  while IFS=$'\t' read -r ip mac; do
    [[ -n "${ip:-}" && -n "${mac:-}" ]] || continue
    mac_ips+=("$ip")
    mac_values+=("$mac")
  done < <(lookup_mac_table)
  progress_current=$((progress_current + 1))
  check_neighbors_progress "$progress_current" "$progress_total"
  for ((index = 0; index < ${#hosts[@]}; index++)); do
    ip="${hosts[$index]}"
    mac=""
    latency="-"
    ping_result=0
    for ((ping_index = 0; ping_index < ${#ping_ips[@]}; ping_index++)); do
      if [[ "${ping_ips[$ping_index]}" == "$ip" ]]; then
        ping_result="${ping_results[$ping_index]}"
        latency="${ping_latencies[$ping_index]}"
        break
      fi
    done
    for ((mac_index = 0; mac_index < ${#mac_ips[@]}; mac_index++)); do
      if [[ "${mac_ips[$mac_index]}" == "$ip" ]]; then
        mac="${mac_values[$mac_index]}"
        break
      fi
    done
    if [[ "$ping_result" -eq 1 ]] || [[ -n "${mac:-}" ]]; then
      active_hosts+=("$ip"$'\t'"${mac:--}"$'\t'"${latency:--}")
    fi
  done
  check_neighbors_progress_done
  if ((${#active_hosts[@]} == 0)); then
    table_print
    return
  fi
  progress_total=${#active_hosts[@]}
  progress_current=0
  for ((index = 0; index < ${#active_hosts[@]}; index++)); do
    IFS=$'\t' read -r ip mac latency <<<"${active_hosts[$index]}"
    hostname="$(resolve_hostname "$ip")"
    table_add_row \
      "$ip" \
      "$mac" \
      "${hostname:--}" \
      "$latency"
    progress_current=$((progress_current + 1))
    check_neighbors_progress "$progress_current" "$progress_total"
  done
  check_neighbors_progress_done
  table_print
}

check_neighbors_progress() {
  printf "\r%s/%s" "$1" "$2" >&2
}

check_neighbors_progress_done() {
  printf "\r%*s\r" 32 "" >&2
}

check_neighbor_ping_table() {
  local ip
  for ip in "$@"; do
    check_neighbor_ping_probe "$ip" &
  done
  wait
}

check_neighbor_ping_probe() {
  local ip
  local ping_output
  local latency
  ip="$1"
  ping_output="$(inspect_host_reachable "$ip" 2>/dev/null || true)"
  latency="$(check_neighbor_ping_latency "$ping_output")"
  if [[ -n "${latency:-}" ]]; then
    printf '%s\t1\t%s\n' "$ip" "$latency"
    return
  fi
  printf '%s\t0\t-\n' "$ip"
}

check_neighbor_ping_latency() {
  awk -F'time=' 'NF > 1 {
    split($2, parts, /[[:space:]]|ms/)
    printf "%.0f ms\n", parts[1]
    exit
  }' <<<"$1"
}
