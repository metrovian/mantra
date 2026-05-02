inspect_network() {
  local netmask_hex

  GATEWAY="$(route -n get default | awk '/gateway:/ {print $2}')"
  IFACE="$(route -n get default | awk '/interface:/ {print $2}')"
  ME="$(
    ifconfig "$IFACE" \
      | awk '/inet / && $2 != "127.0.0.1" {print $2; exit}'
  )"
  netmask_hex="$(
    ifconfig "$IFACE" \
      | awk '/inet / && $2 != "127.0.0.1" {print $4; exit}'
  )"
  PREFIX="$(inspect_netmask_prefix "$netmask_hex")"
}

inspect_host() {
  ping -c 1 -W 1000 "$1" >/dev/null 2>&1 || true
}

inspect_dns_servers() {
  scutil --dns 2>/dev/null \
    | awk '/nameserver\[[0-9]+\]/ {print $3}'
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
