check_local_network() {
  local dns_index
  local dns_server
  local dns_found

  echo "LOCAL"
  echo "--------------------------------------------"
  echo "time    $(date '+%Y-%m-%d %H:%M:%S %Z')"
  echo "iface   $IFACE"
  echo "me      $ME"
  echo "gateway $GATEWAY"
  echo "subnet  ${SUBNET_PREFIX}.0/24"

  dns_index=1
  dns_found=0

  while IFS= read -r dns_server; do
    [[ -z "$dns_server" ]] && continue

    dns_found=1
    echo "dns${dns_index}    $dns_server"

    dns_index=$((dns_index + 1))
  done < <(resolve_dns_servers)

  if [[ "$dns_found" -eq 0 ]]; then
    echo "dns     -"
  fi

  echo
}
