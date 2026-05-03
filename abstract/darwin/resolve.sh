resolve_hostname() {
  if command -v dig >/dev/null 2>&1; then
    dig +short -x "$1" @"$GATEWAY" 2>/dev/null | sed 's/\.$//' | awk 'NR==1 {print; exit}'
    return
  fi
  host "$1" 2>/dev/null \
    | awk '/domain name pointer/ {print $5; exit}' \
    | sed 's/\.$//' \
    || true
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
