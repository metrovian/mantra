check_local_network() {
  print_section "LOCAL"
  echo "time    $(date '+%Y-%m-%d %H:%M:%S %Z')"
  echo "iface   $IFACE"
  echo "me      $ME"
  echo "gateway $GATEWAY"
  echo "subnet  ${SUBNET_PREFIX}.0/24"

  echo
}
