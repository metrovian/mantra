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
