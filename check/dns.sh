check_dns() {
  local -a answers=()
  local -a dns_servers=()
  local latency
  local index
  local dns_index
  local answer_index
  local target
  target="google.com"
  mapfile -t answers < <(resolve_domain_answers "$target")
  mapfile -t dns_servers < <(inspect_dns_servers)
  latency="-"
  if ((${#answers[@]} > 0)); then
    latency="$(dns_ping_latency "$target")"
  fi
  pair_reset
  pair_set_title "DNS"
  pair_add "target" "$target"
  pair_add "latency" "$latency"
  if ((${#dns_servers[@]} == 0)); then
    pair_add "dns" "-"
  else
    dns_index=1
    for ((index = 0; index < ${#dns_servers[@]}; index++)); do
      [[ -n "${dns_servers[$index]}" ]] || continue
      pair_add "dns${dns_index}" "${dns_servers[$index]}"
      dns_index=$((dns_index + 1))
    done
  fi
  if ((${#answers[@]} == 0)); then
    pair_add "answer1" "-"
  else
    answer_index=1
    for ((index = 0; index < ${#answers[@]}; index++)); do
      [[ -n "${answers[$index]}" ]] || continue
      pair_add "answer${answer_index}" "${answers[$index]}"
      answer_index=$((answer_index + 1))
    done
  fi
  pair_print
}

dns_ping_latency() {
  local ping_output
  ping_output="$(inspect_host_reachable "$1" 2>/dev/null || true)"
  awk -F'time=' 'NF > 1 {split($2, parts, /[[:space:]]|ms/); print parts[1] " ms"; exit}' <<<"$ping_output"
}
