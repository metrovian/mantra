detect_network() {
  GATEWAY="$(ip route show default | awk 'NR==1 {print $3}')"
  IFACE="$(ip route show default | awk 'NR==1 {print $5}')"
  LOCAL_IP="$(ip -o -f inet addr show dev "$IFACE" scope global | awk 'NR==1 {split($4, parts, "/"); print parts[1]}')"
}

ping_host() {
  ping -c 1 -W 1 "$1" >/dev/null 2>&1 || true
}

lookup_mac() {
  ip neigh show "$1" | awk '/lladdr/ {print $5; exit}'
}
