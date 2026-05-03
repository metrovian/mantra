check_dns() {
  local -a answers=()
  local -a dns_servers=()
  local latency_ms
  local start_ms
  local end_ms
  local index
  local dns_index
  local answer_index
  local target
  target="naver.com"
  start_ms="$(dns_now_ms)"
  mapfile -t answers < <(resolve_domain_answers "$target")
  end_ms="$(dns_now_ms)"
  latency_ms="$((end_ms - start_ms))"
  mapfile -t dns_servers < <(inspect_dns_servers)
  pair_reset
  pair_set_title "DNS"
  pair_add "target" "$target"
  pair_add "latency" "${latency_ms} ms"
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

dns_now_ms() {
  if command -v perl >/dev/null 2>&1; then
    perl -MTime::HiRes=time -e 'printf "%.0f\n", time() * 1000'
    return
  fi
  date +%s000
}
