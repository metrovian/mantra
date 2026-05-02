check_dns() {
  local target
  local answer
  local answer_count
  local answer_index
  local answer_value
  local latency_ms
  local resolver_count
  local start_ms
  local end_ms

  target="naver.com"
  resolver_count="$(resolve_dns_servers | awk 'NF' | wc -l | tr -d ' ')"
  start_ms="$(dns_now_ms)"
  answer="$(resolve_domain "$target")"
  end_ms="$(dns_now_ms)"
  latency_ms="$((end_ms - start_ms))"
  answer_count="$(resolve_domain_answers "$target" | awk 'NF' | wc -l | tr -d ' ')"

  echo "DNS"
  echo "--------------------------------------------"

  echo "name      $target"
  echo "resolver  $resolver_count"
  echo "answers   $answer_count"
  echo "latency   ${latency_ms} ms"

  if [[ "${answer_count:-0}" -eq 0 ]]; then
    echo "answer    -"
  else
    answer_index=1

    while IFS= read -r answer_value; do
      [[ -z "$answer_value" ]] && continue
      echo "answer${answer_index}   $answer_value"
      answer_index=$((answer_index + 1))
    done < <(resolve_domain_answers "$target")
  fi

  echo
}

dns_now_ms() {
  if command -v perl >/dev/null 2>&1; then
    perl -MTime::HiRes=time -e 'printf "%.0f\n", time() * 1000'
    return
  fi

  date +%s000
}
