detect_network() {
  GATEWAY="$(ip route show default | awk 'NR==1 {print $3}')"
  IFACE="$(ip route show default | awk 'NR==1 {print $5}')"
  ME="$(
    ip -o -f inet addr show dev "$IFACE" scope global \
      | awk 'NR==1 {split($4, parts, "/"); print parts[1]}'
  )"
}

ping_host() {
  ping -c 1 -W 1 "$1" >/dev/null 2>&1 || true
}

lookup_mac() {
  ip neigh show "$1" | awk '/lladdr/ {print $5; exit}'
}

lookup_hostname() {
  getent hosts "$1" 2>/dev/null | awk 'NR==1 {print $2; exit}' || true
}

lookup_company() {
  local prefix

  prefix="$(tr '[:lower:]' '[:upper:]' <<<"$1" | awk -F: '{print $1 $2 $3}')"

  if [[ -f /usr/share/ieee-data/oui.txt ]]; then
    awk -v prefix="$prefix" '
      $1 == prefix && $2 == "(base" && $3 == "16)" {
        $1 = ""
        $2 = ""
        $3 = ""
        sub(/^[ \t]+/, "")
        sub(/\r$/, "")
        print
        exit
      }
    ' /usr/share/ieee-data/oui.txt
    return
  fi

  echo "-"
}
