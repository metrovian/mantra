resolve_hostname() {
  if command -v dig >/dev/null 2>&1; then
    dig +short -x "$1" @"$GATEWAY" 2>/dev/null | sed 's/\.$//' | awk 'NR==1 {print; exit}'
    return
  fi

  getent hosts "$1" 2>/dev/null | awk 'NR==1 {print $2; exit}' || true
}

resolve_dns_servers() {
  if command -v resolvectl >/dev/null 2>&1; then
    resolvectl dns "$IFACE" 2>/dev/null \
      | awk '{
          for (i = 4; i <= NF; i++) {
            print $i
          }
        }'
    return
  fi

  awk '/^nameserver / {print $2}' /etc/resolv.conf 2>/dev/null || true
}

resolve_domain() {
  resolve_domain_answers "$1" | awk 'NR==1 {print; exit}' || true
}

resolve_domain_answers() {
  getent ahostsv4 "$1" 2>/dev/null \
    | awk '{print $1}' \
    | awk '!seen[$0]++' \
    || true
}
