prepare_local_network_context() {
  detect_network

  if [[ -z "${GATEWAY:-}" || -z "${IFACE:-}" || -z "${ME:-}" ]]; then
    echo "could not detect gateway or local IPv4 address." >&2
    exit 1
  fi

  SUBNET_PREFIX="$(awk -F. '{print $1 "." $2 "." $3}' <<<"$GATEWAY")"
}
