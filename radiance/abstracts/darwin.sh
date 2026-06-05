inspect_me() {
  local iface
  iface="$(route -n get default | awk '/interface:/ {print $2}')"
  ifconfig "$iface" \
    | awk '/inet / && $2 != "127.0.0.1" {print $2; exit}'
}

inspect_network() {
  local gateway
  local iface
  local me
  local netmask_hex
  local prefix
  local subnet_cidr
  gateway="$(route -n get default | awk '/gateway:/ {print $2}')"
  iface="$(route -n get default | awk '/interface:/ {print $2}')"
  me="$(
    ifconfig "$iface" \
      | awk '/inet / && $2 != "127.0.0.1" {print $2; exit}'
  )"
  netmask_hex="$(
    ifconfig "$iface" \
      | awk '/inet / && $2 != "127.0.0.1" {print $4; exit}'
  )"
  prefix="$(inspect_netmask_prefix "$netmask_hex")"
  subnet_cidr="$(inspect_subnet_cidr "$me" "$netmask_hex" "$prefix")"
  printf '%s\t%s\t%s\t%s\n' "$gateway" "$iface" "$me" "$subnet_cidr"
}

inspect_netmask_prefix() {
  local netmask_hex
  local value
  local bit
  local prefix
  netmask_hex="${1#0x}"
  value=$((16#$netmask_hex))
  prefix=0
  for ((bit = 31; bit >= 0; bit--)); do
    if (((value >> bit) & 1)); then
      prefix=$((prefix + 1))
    fi
  done
  echo "$prefix"
}

inspect_subnet_cidr() {
  local a b c d value prefix ip subnet
  IFS=. read -r a b c d <<<"$1"
  value=$((16#${2#0x}))
  prefix="$3"
  ip=$((((a << 24) | (b << 16) | (c << 8) | d)))
  subnet=$((ip & value))
  printf '%d.%d.%d.%d/%s\n' \
    "$(((subnet >> 24) & 255))" \
    "$(((subnet >> 16) & 255))" \
    "$(((subnet >> 8) & 255))" \
    "$((subnet & 255))" \
    "$prefix"
}
