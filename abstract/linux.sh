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

inspect_host_reachable() {
  ping -c 1 -W 0.2 "$1"
}

lookup_mac_table() {
  ip neigh show 2>/dev/null \
    | awk '
        /lladdr/ {
          print $1 "\t" tolower($5)
        }
      ' \
    | awk '!seen[$1]++'
}

resolve_hostname() {
  if command -v dig >/dev/null 2>&1; then
    dig +short -x "$1" @"$GATEWAY" 2>/dev/null | sed 's/\.$//' | awk 'NR==1 {print; exit}'
    return
  fi
  getent hosts "$1" 2>/dev/null | awk 'NR==1 {print $2; exit}' || true
}
