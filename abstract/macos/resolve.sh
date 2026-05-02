resolve_hostname() {
  host "$1" 2>/dev/null \
    | awk '/domain name pointer/ {print $5; exit}' \
    | sed 's/\.$//' \
    || true
}

resolve_dns_servers() {
  scutil --dns 2>/dev/null \
    | awk '/nameserver\[[0-9]+\]/ {print $3}'
}

resolve_domain() {
  resolve_domain_answers "$1" | awk 'NR==1 {print; exit}' || true
}

resolve_domain_answers() {
  local answers

  answers="$(
    dscacheutil -q host -a name "$1" 2>/dev/null \
      | awk '/^ip_address: / {print $2}'
  )"

  if [[ -n "$answers" ]]; then
    awk '!seen[$0]++' <<<"$answers"
    return
  fi

  host "$1" 2>/dev/null \
    | awk '/has address/ {print $4}' \
    | awk '!seen[$0]++' \
    || true
}
