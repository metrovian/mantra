check_local_network() {
  echo "time    $(date '+%Y-%m-%d %H:%M:%S %Z')"
  echo "iface   $IFACE"
  echo "me      $LOCAL_IP"
  echo "gateway $GATEWAY"
  echo "subnet  ${SUBNET_PREFIX}.0/24"
  echo
}
