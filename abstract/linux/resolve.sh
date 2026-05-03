resolve_hostname() {
  if command -v dig >/dev/null 2>&1; then
    dig +short -x "$1" @"$GATEWAY" 2>/dev/null | sed 's/\.$//' | awk 'NR==1 {print; exit}'
    return
  fi

  getent hosts "$1" 2>/dev/null | awk 'NR==1 {print $2; exit}' || true
}

resolve_domain_answers() {
  getent ahostsv4 "$1" 2>/dev/null \
    | awk '{print $1}' \
    | awk '!seen[$0]++' \
    || true
}
