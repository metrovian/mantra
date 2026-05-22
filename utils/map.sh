map_prepare_context() {
  sudo -v
  inspect_network
  [[ -n "${GATEWAY:-}" && -n "${IFACE:-}" && -n "${ME:-}" && -n "${PREFIX:-}" ]] || return 1
  SUBNET="$(network_subnet_address "$ME" "$PREFIX")"
  SUBNET_CIDR="${SUBNET}/${PREFIX}"
}

map_local() {
  pair_reset
  pair_set_title "LOCAL"
  pair_add "time" "$(date '+%Y-%m-%d %H:%M:%S %Z')"
  pair_add "iface" "$IFACE"
  pair_add "me" "$ME"
  pair_add "gateway" "$GATEWAY"
  pair_add "subnet" "$SUBNET_CIDR"
  pair_print
}

map_neighbors() {
  local ip
  local mac
  local oui
  local ssh
  table_reset
  table_set_headers "IP" "MAC" "OUI" "SSH"
  while IFS=$'\t' read -r ip mac oui ssh; do
    [[ -n "${ip:-}" ]] || continue
    table_add_row "$ip" "$mac" "$oui" "$ssh"
  done < <(
    map_neighbors_scan "$SUBNET_CIDR" | map_neighbors_parse
  )
  table_print
}

map_neighbors_scan() {
  sudo nmap \
    -n \
    -p 22 \
    --exclude "$ME" \
    "$1" 2>/dev/null || true
}

map_neighbors_parse() {
  awk '
    function emit() {
      if (ip == "") {
        return
      }
      if (mac == "") {
        mac = "-"
      }
      if (oui == "") {
        oui = "-"
      }
      if (ssh == "") {
        ssh = "-"
      }
      print ip "\t" mac "\t" oui "\t" ssh
    }
    /^Nmap scan report for / {
      emit()
      ip = $NF
      mac = "-"
      oui = "-"
      ssh = "-"
      next
    }
    /^22\/tcp[[:space:]]+open[[:space:]]+ssh$/ {
      ssh = "o"
      next
    }
    /^MAC Address: / {
      mac = tolower($3)
      oui = $0
      sub(/^MAC Address: [^ ]+[[:space:]]*/, "", oui)
      gsub(/^\(/, "", oui)
      gsub(/\)$/, "", oui)
      if (oui == "") {
        oui = "-"
      }
    }
    /^Nmap done:/ {
      emit()
      ip = ""
    }
    END {
      emit()
    }
  '
}
