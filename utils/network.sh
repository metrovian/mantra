network_ip_to_int() {
  local a
  local b
  local c
  local d
  IFS=. read -r a b c d <<<"$1"
  echo $((((a << 24) | (b << 16) | (c << 8) | d)))
}

network_int_to_ip() {
  local value
  value="$1"
  echo "$(((value >> 24) & 255)).$(((value >> 16) & 255)).$(((value >> 8) & 255)).$((value & 255))"
}

network_prefix_mask() {
  local prefix
  prefix="$1"
  if ((prefix == 0)); then
    echo 0
    return
  fi
  echo $(((0xFFFFFFFF << (32 - prefix)) & 0xFFFFFFFF))
}

network_subnet_address() {
  local ip_int
  local mask_int
  ip_int="$(network_ip_to_int "$1")"
  mask_int="$(network_prefix_mask "$2")"
  network_int_to_ip "$((ip_int & mask_int))"
}
