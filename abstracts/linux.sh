inspect_network() {
  local cidr
  local subnet_cidr
  GATEWAY="$(ip route show default | awk 'NR==1 {print $3}')"
  IFACE="$(ip route show default | awk 'NR==1 {print $5}')"
  cidr="$(
    ip -o -f inet addr show dev "$IFACE" scope global \
      | awk 'NR==1 {print $4}'
  )"
  ME="$(awk -F/ 'NR==1 {print $1}' <<<"$cidr")"
  PREFIX="$(awk -F/ 'NR==1 {print $2}' <<<"$cidr")"
  subnet_cidr="$(
    ip route show dev "$IFACE" proto kernel scope link \
      | awk 'NR==1 {print $1}'
  )"
  SUBNET_CIDR="${subnet_cidr:-$cidr}"
}
