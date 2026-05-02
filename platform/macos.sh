detect_network() {
  GATEWAY="$(route -n get default | awk '/gateway:/ {print $2}')"
  IFACE="$(route -n get default | awk '/interface:/ {print $2}')"
  LOCAL_IP="$(ifconfig "$IFACE" | awk '/inet / && $2 != "127.0.0.1" {print $2; exit}')"
}

ping_host() {
  ping -c 1 -W 1000 "$1" >/dev/null 2>&1 || true
}

lookup_mac() {
  arp -n "$1" | awk '/ at / {print $4; exit}'
}
