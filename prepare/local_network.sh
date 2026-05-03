prepare_local_network_context() {
  inspect_network
  if [[ -z "${GATEWAY:-}" || -z "${IFACE:-}" || -z "${ME:-}" || -z "${PREFIX:-}" ]]; then
    echo "could not detect gateway or local IPv4 address." >&2
    exit 1
  fi
  SUBNET="$(network_subnet_address "$ME" "$PREFIX")"
  SUBNET_FIRST="$(network_subnet_first_host "$SUBNET" "$PREFIX")"
  SUBNET_LAST="$(network_subnet_last_host "$SUBNET" "$PREFIX")"
}
