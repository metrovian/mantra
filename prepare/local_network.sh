prepare_local_network_context() {
  inspect_network

  if [[ -z "${GATEWAY:-}" || -z "${IFACE:-}" || -z "${ME:-}" || -z "${PREFIX:-}" ]]; then
    echo "could not detect gateway or local IPv4 address." >&2
    exit 1
  fi

  SUBNET="$(prepare_network_address "$ME" "$PREFIX")"
  SUBNET_FIRST="$(prepare_network_first_host "$SUBNET" "$PREFIX")"
  SUBNET_LAST="$(prepare_network_last_host "$SUBNET" "$PREFIX")"
}

prepare_ip_to_int() {
  local a
  local b
  local c
  local d

  IFS=. read -r a b c d <<<"$1"
  echo $((((a << 24) | (b << 16) | (c << 8) | d)))
}

prepare_int_to_ip() {
  local value

  value="$1"
  echo "$(((value >> 24) & 255)).$(((value >> 16) & 255)).$(((value >> 8) & 255)).$((value & 255))"
}

prepare_prefix_mask() {
  local prefix

  prefix="$1"

  if ((prefix == 0)); then
    echo 0
    return
  fi

  echo $(((0xFFFFFFFF << (32 - prefix)) & 0xFFFFFFFF))
}

prepare_network_address() {
  local ip_int
  local mask_int

  ip_int="$(prepare_ip_to_int "$1")"
  mask_int="$(prepare_prefix_mask "$2")"
  prepare_int_to_ip "$((ip_int & mask_int))"
}

prepare_network_first_host() {
  local subnet_int
  local prefix

  subnet_int="$(prepare_ip_to_int "$1")"
  prefix="$2"

  if ((prefix >= 31)); then
    prepare_int_to_ip "$subnet_int"
    return
  fi

  prepare_int_to_ip "$((subnet_int + 1))"
}

prepare_network_last_host() {
  local subnet_int
  local prefix
  local mask_int
  local broadcast_int

  subnet_int="$(prepare_ip_to_int "$1")"
  prefix="$2"
  mask_int="$(prepare_prefix_mask "$prefix")"
  broadcast_int=$((subnet_int | (0xFFFFFFFF ^ mask_int)))

  if ((prefix >= 31)); then
    prepare_int_to_ip "$broadcast_int"
    return
  fi

  prepare_int_to_ip "$((broadcast_int - 1))"
}
