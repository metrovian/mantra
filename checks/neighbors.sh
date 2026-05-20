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
  local ping_row
  local index
  local ping_done_count
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
  total_hosts="$(network_subnet_host_count "$SUBNET_FIRST" "$SUBNET_LAST" "$ME")"
  table_reset
  table_set_headers "IP" "MAC" "NAME" "RTT"
  if ((total_hosts == 0)); then
    table_print
    return
  fi
  progress_total=$total_hosts
  if [[ "$IFACE" != "manual" ]]; then
    progress_total=$((progress_total + 1))
  fi
  progress_current=0
  ping_done_count=0
  check_neighbors_progress_count "ping" "$ping_done_count" "$progress_total"
  pipe_dir="$(mktemp -d)"
  ping_dir="$pipe_dir/ping"
  mac_pipe="$pipe_dir/mac"
  mdns_pipe="$pipe_dir/mdns"
  mkdir "$ping_dir"
  mkfifo "$mac_pipe" "$mdns_pipe"
  trap "rm -rf '$pipe_dir'" RETURN
  index=0
  for ((host_int = first_int; host_int <= last_int; host_int++)); do
    ip="$(network_int_to_ip "$host_int")"
    if [[ "$ip" == "$ME" ]]; then
      continue
    fi
    hosts+=("$ip")
    check_neighbor_ping_capture "$index" "$ip" "$ping_dir" &
    index=$((index + 1))
  done
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
    check_neighbors_collect_pairs \
      "$mac_pipe" \
      mac_ips \
      mac_values
  fi
  if [[ "$IFACE" != "manual" ]]; then
    progress_current=$((progress_current + 1))
  fi
  for ((index = 0; index < ${#hosts[@]}; index++)); do
    ip="${hosts[$index]}"
    ping_row="$(check_neighbors_find_ping \
      ping_ips \
      ping_results \
      ping_rtts \
      "$ip")"
    IFS=$'\t' read -r ping_result rtt <<<"$ping_row"
    mac="$(check_neighbors_find_value mac_ips mac_values "$ip")"
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
    check_neighbors_collect_pairs \
      "$mdns_pipe" \
      hostname_ips \
      hostname_values
  fi
  for ((index = 0; index < ${#active_hosts[@]}; index++)); do
    IFS=$'\t' read -r ip mac rtt <<<"${active_hosts[$index]}"
    hostname="$(check_neighbors_find_value \
      hostname_ips \
      hostname_values \
      "$ip")"
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

check_neighbors_collect_pairs() {
  local input_path
  local keys_name
  local values_name
  local key
  local value
  input_path="$1"
  keys_name="$2"
  values_name="$3"
  while IFS=$'\t' read -r key value; do
    [[ -n "${key:-}" && -n "${value:-}" ]] || continue
    eval "$keys_name+=(\"\$key\")"
    eval "$values_name+=(\"\$value\")"
  done <"$input_path"
}

check_neighbors_find_value() {
  local keys_name
  local values_name
  local target
  local count
  local index
  local key
  local value
  keys_name="$1"
  values_name="$2"
  target="$3"
  eval "count=\${#$keys_name[@]}"
  for ((index = 0; index < count; index++)); do
    eval "key=\${$keys_name[$index]}"
    if [[ "$key" == "$target" ]]; then
      eval "value=\${$values_name[$index]}"
      printf '%s\n' "$value"
      return
    fi
  done
}

check_neighbors_find_ping() {
  local keys_name
  local results_name
  local rtts_name
  local target
  local count
  local index
  local key
  local result
  local rtt
  keys_name="$1"
  results_name="$2"
  rtts_name="$3"
  target="$4"
  eval "count=\${#$keys_name[@]}"
  for ((index = 0; index < count; index++)); do
    eval "key=\${$keys_name[$index]}"
    if [[ "$key" == "$target" ]]; then
      eval "result=\${$results_name[$index]}"
      eval "rtt=\${$rtts_name[$index]}"
      printf '%s\t%s\n' "$result" "$rtt"
      return
    fi
  done
  printf '0\t-\n'
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
