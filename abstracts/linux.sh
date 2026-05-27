inspect_me() {
  local cidr
  local iface
  iface="$(ip route show default | awk 'NR==1 {print $5}')"
  cidr="$(
    ip -o -f inet addr show dev "$iface" scope global \
      | awk 'NR==1 {print $4}'
  )"
  awk -F/ 'NR==1 {print $1}' <<<"$cidr"
}

inspect_network() {
  local cidr
  local gateway
  local iface
  local me
  local subnet_cidr
  gateway="$(ip route show default | awk 'NR==1 {print $3}')"
  iface="$(ip route show default | awk 'NR==1 {print $5}')"
  cidr="$(
    ip -o -f inet addr show dev "$iface" scope global \
      | awk 'NR==1 {print $4}'
  )"
  me="$(awk -F/ 'NR==1 {print $1}' <<<"$cidr")"
  subnet_cidr="$(
    ip route show dev "$iface" proto kernel scope link \
      | awk 'NR==1 {print $1}'
  )"
  printf '%s\t%s\t%s\t%s\n' "$gateway" "$iface" "$me" "${subnet_cidr:-$cidr}"
}
