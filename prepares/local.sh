prepare_local_context() {
  if [[ -n "${GATEWAY:-}" && -n "${ME:-}" && -n "${PREFIX:-}" ]]; then
    IFACE="${IFACE:-manual}"
  else
    inspect_network
  fi
  if [[ "${IFACE:-}" == "manual" ]]; then
    NEIGHBOR_MAC_LOOKUP="${NEIGHBOR_MAC_LOOKUP:-0}"
    NEIGHBOR_MDNS_BROWSE="${NEIGHBOR_MDNS_BROWSE:-0}"
  else
    NEIGHBOR_MAC_LOOKUP="${NEIGHBOR_MAC_LOOKUP:-1}"
    NEIGHBOR_MDNS_BROWSE="${NEIGHBOR_MDNS_BROWSE:-1}"
  fi
  if [[ -z "${GATEWAY:-}" || -z "${IFACE:-}" || -z "${ME:-}" || -z "${PREFIX:-}" ]]; then
    echo "could not detect gateway or local IPv4 address." >&2
    exit 1
  fi
  SUBNET="$(network_subnet_address "$ME" "$PREFIX")"
  SUBNET_FIRST="$(network_subnet_first_host "$SUBNET" "$PREFIX")"
  SUBNET_LAST="$(network_subnet_last_host "$SUBNET" "$PREFIX")"
}
