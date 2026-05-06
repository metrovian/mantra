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
  ping -c 1 -W 0.2 "$1"
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

inspect_mdns_browse_table() {
  if ! command -v avahi-browse >/dev/null 2>&1; then
    return
  fi
  (timeout 0.2s avahi-browse --parsable --all --resolve 2>/dev/null || true) \
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

resolve_mdns_hostname() {
  if command -v avahi-resolve-address >/dev/null 2>&1; then
    (timeout 0.2s avahi-resolve-address "$1" 2>/dev/null || true) \
      | awk 'NR==1 {print $2; exit}' \
      | resolve_mdns_clean_name
    return
  fi
  if command -v dig >/dev/null 2>&1; then
    dig +short -x "$1" @224.0.0.251 -p 5353 2>/dev/null \
      | resolve_mdns_clean_name \
      | awk 'NR==1 {print; exit}'
  fi
}
