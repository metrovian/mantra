inspect_network() {
  GATEWAY="$(ip route show default | awk 'NR==1 {print $3}')"
  IFACE="$(ip route show default | awk 'NR==1 {print $5}')"
  ME="$(
    ip -o -f inet addr show dev "$IFACE" scope global \
      | awk 'NR==1 {split($4, parts, "/"); print parts[1]}'
  )"
  PREFIX="$(
    ip -o -f inet addr show dev "$IFACE" scope global \
      | awk 'NR==1 {split($4, parts, "/"); print parts[2]}'
  )"
}

inspect_host_reachable() {
  ping -c 1 -W "$INSPECT_TIMEOUT" "$1"
}

inspect_mdns_browse_table() {
  (
    timeout "${MDNS_BROWSE_TIMEOUT}s" \
      avahi-browse --parsable --all --resolve 2>/dev/null || true
  ) \
    | awk -F';' '
        $1 == "=" && $7 != "" && $8 != "" {
          host = $7
          print $8 "\t" host
        }
      ' \
    | awk -F'\t' '{
        host = $2
        sub(/\.$/, "", host)
        sub(/\.local$/, "", host)
        print $1 "\t" host
      }' \
    | awk '!seen[$1]++'
}

lookup_mac_table() {
  ip neigh show 2>/dev/null \
    | awk '
        /lladdr/ {
          print $1 "\t" tolower($5)
        }
      ' \
    | awk '!seen[$1]++'
}

resolve_mdns_hostname() {
  (
    timeout "${MDNS_RESOLVE_TIMEOUT}s" \
      avahi-resolve-address "$1" 2>/dev/null || true
  ) \
    | awk 'NR==1 {print $2; exit}' \
    | resolve_mdns_clean_name
}
