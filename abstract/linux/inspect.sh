inspect_network() {
  GATEWAY="$(ip route show default | awk 'NR==1 {print $3}')"
  IFACE="$(ip route show default | awk 'NR==1 {print $5}')"
  ME="$(
    ip -o -f inet addr show dev "$IFACE" scope global \
      | awk 'NR==1 {split($4, parts, "/"); print parts[1]}'
  )"
  PREFIX="$(
    ip -o -f inet addr show dev "$IFACE" scope global \
      | awk 'NR==1 {split($4, parts, "/"); print parts[2]}'
  )"
}

inspect_host() {
  ping -c 1 -W 1 "$1" >/dev/null 2>&1 || true
}

inspect_dns_servers() {
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
