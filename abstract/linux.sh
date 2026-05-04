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

inspect_host() {
  inspect_host_reachable "$1" >/dev/null 2>&1 || true
}

inspect_host_reachable() {
  ping -c 1 -W 0.2 "$1"
}

inspect_dns_servers() {
  if command -v resolvectl >/dev/null 2>&1; then
    resolvectl dns "$IFACE" 2>/dev/null \
      | awk '{
          for (i = 4; i <= NF; i++) {
            print $i
          }
        }'
    return
  fi
  awk '/^nameserver / {print $2}' /etc/resolv.conf 2>/dev/null || true
}

lookup_mac() {
  ip neigh show "$1" | awk '/lladdr/ {print $5; exit}' | awk 'NR==1 {print; exit}'
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

lookup_company() {
  local company
  company="$(lookup_company_from_oui_files "$1" /usr/share/ieee-data/oui.txt)"
  [[ -n "$company" ]] && { echo "$company"; return; }
  echo "-"
}

resolve_hostname() {
  if command -v dig >/dev/null 2>&1; then
    dig +short -x "$1" @"$GATEWAY" 2>/dev/null | sed 's/\.$//' | awk 'NR==1 {print; exit}'
    return
  fi
  getent hosts "$1" 2>/dev/null | awk 'NR==1 {print $2; exit}' || true
}

resolve_domain_answers() {
  getent ahostsv4 "$1" 2>/dev/null \
    | awk '{print $1}' \
    | awk '!seen[$0]++' \
    || true
}
