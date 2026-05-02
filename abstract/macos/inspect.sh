inspect_network() {
  GATEWAY="$(route -n get default | awk '/gateway:/ {print $2}')"
  IFACE="$(route -n get default | awk '/interface:/ {print $2}')"
  ME="$(
    ifconfig "$IFACE" \
      | awk '/inet / && $2 != "127.0.0.1" {print $2; exit}'
  )"
}

inspect_host() {
  ping -c 1 -W 1000 "$1" >/dev/null 2>&1 || true
}

inspect_dns_servers() {
  scutil --dns 2>/dev/null \
    | awk '/nameserver\[[0-9]+\]/ {print $3}'
}
