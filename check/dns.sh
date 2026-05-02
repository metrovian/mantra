check_dns() {
  local target
  local answers
  local answer_index
  local answer_value
  local dns_index
  local dns_server
  local dns_found
  local latency_ms
  local start_ms
  local end_ms

  target="naver.com"
  dns_index=1
  dns_found=0
  start_ms="$(dns_now_ms)"
  answers="$(resolve_domain_answers "$target")"
  end_ms="$(dns_now_ms)"
  latency_ms="$((end_ms - start_ms))"

  pair_reset
  pair_set_title "DNS"
  pair_add "target" "$target"
  pair_add "latency" "${latency_ms} ms"

  while IFS= read -r dns_server; do
    [[ -z "$dns_server" ]] && continue

    dns_found=1
    pair_add "dns${dns_index}" "$dns_server"
    dns_index=$((dns_index + 1))
  done < <(inspect_dns_servers)

  if [[ "$dns_found" -eq 0 ]]; then
    pair_add "dns" "-"
  fi

  if [[ -z "$answers" ]]; then
    pair_add "answer1" "-"
  else
    answer_index=1

    while IFS= read -r answer_value; do
      [[ -z "$answer_value" ]] && continue
      pair_add "answer${answer_index}" "$answer_value"
      answer_index=$((answer_index + 1))
    done <<<"$answers"
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
