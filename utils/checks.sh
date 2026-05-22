check_prepare_context() {
  if [[ -n "${GATEWAY:-}" && -n "${ME:-}" && -n "${PREFIX:-}" ]]; then
    IFACE="${IFACE:-manual}"
  else
    inspect_network
  fi
  if [[ -z "${GATEWAY:-}" || -z "${IFACE:-}" || -z "${ME:-}" || -z "${PREFIX:-}" ]]; then
    echo "could not detect gateway or local IPv4 address." >&2
    exit 1
  fi
  if ! command -v nmap >/dev/null 2>&1; then
    echo "nmap is required. run 3rdparty/setup-$OS.sh first." >&2
    exit 1
  fi
  check_prepare_sudo
  SUBNET="$(network_subnet_address "$ME" "$PREFIX")"
  SUBNET_CIDR="${SUBNET}/${PREFIX}"
}

check_prepare_sudo() {
  if ((EUID == 0)); then
    return
  fi
  if ! command -v sudo >/dev/null 2>&1; then
    echo "sudo is required to run nmap." >&2
    exit 1
  fi
  sudo -v
}

check_local() {
  pair_reset
  pair_set_title "LOCAL"
  pair_add "time" "$(date '+%Y-%m-%d %H:%M:%S %Z')"
  pair_add "iface" "$IFACE"
  pair_add "me" "$ME"
  pair_add "gateway" "$GATEWAY"
  pair_add "subnet" "$SUBNET_CIDR"
  pair_print
}

check_neighbors() {
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
    check_neighbors_scan "$SUBNET_CIDR" | check_neighbors_parse
  )
  table_print
}

check_neighbors_scan() {
  sudo nmap \
    -n \
    -p 22 \
    --exclude "$ME" \
    "$1" 2>/dev/null || true
}

check_neighbors_parse() {
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
