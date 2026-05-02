resolve_hostname() {
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
  getent ahostsv4 "$1" 2>/dev/null | awk 'NR==1 {print $1; exit}' || true
}
