check_neighbors() {
  local -a active_hosts=()
  local -a hosts=()
  local -a hostname_ips=()
  local -a hostname_values=()
  local -a mac_ips=()
  local -a mac_values=()
  local -a ping_ips=()
  local -a ping_results=()
  local -a ping_rtts=()
  local ip
  local rtt
  local mac
  local hostname
  local total_hosts
  local progress_total
  local progress_current
  local index
  local ping_done_count
  local hostname_index
  local mac_index
  local ping_index
  local ping_result
  local first_int
  local last_int
  local host_int
  local pipe_dir
  local ping_dir
  local mac_pipe
  local mdns_pipe
  first_int="$(network_ip_to_int "$SUBNET_FIRST")"
  last_int="$(network_ip_to_int "$SUBNET_LAST")"
  for ((host_int = first_int; host_int <= last_int; host_int++)); do
    ip="$(network_int_to_ip "$host_int")"
    if [[ "$ip" != "$ME" ]]; then
      hosts+=("$ip")
    fi
  done
  total_hosts=${#hosts[@]}
  table_reset
  table_set_headers "IP" "MAC" "NAME" "RTT"
  if ((total_hosts == 0)); then
    table_print
    return
  fi
  progress_total=$((total_hosts + 1))
  progress_current=0
  pipe_dir="$(mktemp -d)"
  ping_dir="$pipe_dir/ping"
  mac_pipe="$pipe_dir/mac"
  mdns_pipe="$pipe_dir/mdns"
  mkdir "$ping_dir"
  mkfifo "$mac_pipe" "$mdns_pipe"
  trap "rm -rf '$pipe_dir'" RETURN
  for ((index = 0; index < ${#hosts[@]}; index++)); do
    ip="${hosts[$index]}"
    check_neighbor_ping_capture "$index" "$ip" "$ping_dir" &
  done
  ping_done_count=0
  while ((ping_done_count < total_hosts)); do
    ping_done_count=0
    for ((index = 0; index < ${#hosts[@]}; index++)); do
      if [[ -f "$ping_dir/$index.out" ]]; then
        ping_done_count=$((ping_done_count + 1))
      fi
    done
    check_neighbors_progress_count "ping" "$ping_done_count" "$progress_total"
    if ((ping_done_count < total_hosts)); then
      sleep 0.1
    fi
  done
  wait
  for ((index = 0; index < ${#hosts[@]}; index++)); do
    IFS=$'\t' read -r ip ping_result rtt <"$ping_dir/$index.out"
    ping_ips+=("$ip")
    ping_results+=("$ping_result")
    ping_rtts+=("$rtt")
  done
  progress_current=$total_hosts
  if [[ "$IFACE" != "manual" ]]; then
    lookup_mac_table >"$mac_pipe" &
    while IFS=$'\t' read -r ip mac; do
      [[ -n "${ip:-}" && -n "${mac:-}" ]] || continue
      mac_ips+=("$ip")
      mac_values+=("$mac")
    done <"$mac_pipe"
  fi
  progress_current=$((progress_current + 1))
  for ((index = 0; index < ${#hosts[@]}; index++)); do
    ip="${hosts[$index]}"
    mac=""
    rtt="-"
    ping_result=0
    for ((ping_index = 0; ping_index < ${#ping_ips[@]}; ping_index++)); do
      if [[ "${ping_ips[$ping_index]}" == "$ip" ]]; then
        ping_result="${ping_results[$ping_index]}"
        rtt="${ping_rtts[$ping_index]}"
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
      active_hosts+=("$ip"$'\t'"${mac:--}"$'\t'"${rtt:--}")
    fi
  done
  check_neighbors_progress_done
  if ((${#active_hosts[@]} == 0)); then
    table_print
    return
  fi
  progress_total=${#active_hosts[@]}
  progress_current=0
  if [[ "$IFACE" != "manual" ]]; then
    check_neighbors_progress_count "mdns" "$progress_current" "$progress_total"
    inspect_mdns_browse_table >"$mdns_pipe" &
    while IFS=$'\t' read -r ip hostname; do
      [[ -n "${ip:-}" && -n "${hostname:-}" ]] || continue
      hostname_ips+=("$ip")
      hostname_values+=("$hostname")
    done <"$mdns_pipe"
  fi
  for ((index = 0; index < ${#active_hosts[@]}; index++)); do
    local active_row
    local active_rest
    active_row="${active_hosts[$index]}"
    ip="${active_row%%$'\t'*}"
    active_rest="${active_row#*$'\t'}"
    mac="${active_rest%%$'\t'*}"
    rtt="${active_rest#*$'\t'}"
    hostname=""
    for ((hostname_index = 0; hostname_index < ${#hostname_ips[@]}; hostname_index++)); do
      if [[ "${hostname_ips[$hostname_index]}" == "$ip" ]]; then
        hostname="${hostname_values[$hostname_index]}"
        break
      fi
    done
    if [[ -z "${hostname:-}" ]]; then
      hostname="$(resolve_mdns_hostname "$ip")"
    fi
    table_add_row \
      "$ip" \
      "$mac" \
      "${hostname:--}" \
      "$rtt"
    progress_current=$((progress_current + 1))
    check_neighbors_progress_count "mdns" "$progress_current" "$progress_total"
  done
  check_neighbors_progress_done
  table_print
}

check_neighbors_progress_count() {
  printf '\r\033[2K%s %s/%s' "$1" "$2" "$3" >&2
}

check_neighbors_progress_done() {
  printf '\r\033[2K' >&2
}

check_neighbor_ping_table() {
  local concurrent
  local limit
  local ip
  concurrent=0
  limit="$INSPECT_CONCURRENCY"
  for ip in "$@"; do
    check_neighbor_ping_probe "$ip" &
    concurrent=$((concurrent + 1))
    if ((concurrent >= limit)); then
      wait
      concurrent=0
    fi
  done
  wait
}

check_neighbor_ping_capture() {
  local index
  local ip
  local output_dir
  index="$1"
  ip="$2"
  output_dir="$3"
  check_neighbor_ping_probe "$ip" >"$output_dir/$index.tmp"
  mv "$output_dir/$index.tmp" "$output_dir/$index.out"
}

check_neighbor_ping_probe() {
  local ip
  local ping_output
  local rtt
  ip="$1"
  ping_output="$(inspect_host_reachable "$ip" 2>/dev/null || true)"
  rtt="$(check_neighbor_ping_rtt "$ping_output")"
  if [[ -n "${rtt:-}" ]]; then
    printf '%s\t1\t%s\n' "$ip" "$rtt"
    return
  fi
  printf '%s\t0\t-\n' "$ip"
}

check_neighbor_ping_rtt() {
  printf '%s\n' "$1" | awk -F'time=' 'NF > 1 {
    split($2, parts, /[[:space:]]|ms/)
    printf "%.0f ms\n", parts[1]
    exit
  }'
}
