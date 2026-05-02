check_local_network() {
  pair_reset
  pair_set_title "LOCAL"
  pair_add "time" "$(date '+%Y-%m-%d %H:%M:%S %Z')"
  pair_add "iface" "$IFACE"
  pair_add "me" "$ME"
  pair_add "gateway" "$GATEWAY"
  pair_add "subnet" "${SUBNET}/${PREFIX}"
  pair_print
}
