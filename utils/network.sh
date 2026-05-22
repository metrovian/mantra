network_subnet_address() {
  local a
  local b
  local c
  local d
  local prefix
  local ip_int
  local mask_int
  local subnet_int
  IFS=. read -r a b c d <<<"$1"
  prefix="$2"
  ip_int=$((((a << 24) | (b << 16) | (c << 8) | d)))
  if ((prefix == 0)); then
    mask_int=0
  else
    mask_int=$(((0xFFFFFFFF << (32 - prefix)) & 0xFFFFFFFF))
  fi
  subnet_int=$((ip_int & mask_int))
  echo "$(((subnet_int >> 24) & 255)).$(((subnet_int >> 16) & 255)).$(((subnet_int >> 8) & 255)).$((subnet_int & 255))"
}
