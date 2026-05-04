lookup_format_mac() {
  local mac
  local -a octets
  mac="$1"
  IFS=: read -r -a octets <<<"$mac"
  if ((${#octets[@]} != 6)); then
    echo "$mac"
    return
  fi
  printf '%02x:%02x:%02x:%02x:%02x:%02x\n' \
    "$((16#${octets[0]}))" \
    "$((16#${octets[1]}))" \
    "$((16#${octets[2]}))" \
    "$((16#${octets[3]}))" \
    "$((16#${octets[4]}))" \
    "$((16#${octets[5]}))"
}
