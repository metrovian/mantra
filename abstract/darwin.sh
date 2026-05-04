inspect_network() {
  local netmask_hex
  GATEWAY="$(route -n get default | awk '/gateway:/ {print $2}')"
  IFACE="$(route -n get default | awk '/interface:/ {print $2}')"
  ME="$(
    ifconfig "$IFACE" \
      | awk '/inet / && $2 != "127.0.0.1" {print $2; exit}'
  )"
  netmask_hex="$(
    ifconfig "$IFACE" \
      | awk '/inet / && $2 != "127.0.0.1" {print $4; exit}'
  )"
  PREFIX="$(inspect_netmask_prefix "$netmask_hex")"
}

inspect_host() {
  inspect_host_reachable "$1" >/dev/null 2>&1 || true
}

inspect_host_reachable() {
  ping -c 1 -W 200 "$1"
}

inspect_dns_servers() {
  scutil --dns 2>/dev/null \
    | awk '
        /nameserver\[[0-9]+\]/ {
          if (!seen[$3]++) {
            print $3
          }
        }
      '
}

inspect_netmask_prefix() {
  local netmask_hex
  local value
  local bit
  local prefix
  netmask_hex="${1#0x}"
  value=$((16#$netmask_hex))
  prefix=0
  for ((bit = 31; bit >= 0; bit--)); do
    if (((value >> bit) & 1)); then
      prefix=$((prefix + 1))
    fi
  done
  echo "$prefix"
}

lookup_mac() {
  local mac
  mac="$(arp -n "$1" 2>/dev/null | awk '/ at / {print $4; exit}' || true)"
  [[ -n "$mac" ]] && lookup_format_mac "$mac"
}

lookup_mac_table() {
  arp -an 2>/dev/null \
    | awk '
        / at / && $4 != "(incomplete)" {
          ip = $2
          gsub(/[()]/, "", ip)
          print ip "\t" tolower($4)
        }
      ' \
    | awk '!seen[$1]++'
}

lookup_company() {
  local company
  company="$(lookup_company_from_oui_files "$1" \
    /usr/share/ieee-data/oui.txt \
    /opt/homebrew/share/ieee-data/oui.txt \
    /usr/local/share/ieee-data/oui.txt)"
  [[ -n "$company" ]] && { echo "$company"; return; }
  company="$(lookup_company_from_manuf_files "$1" \
    /opt/homebrew/etc/wireshark/manuf \
    /usr/local/etc/wireshark/manuf \
    /Applications/Wireshark.app/Contents/Resources/share/wireshark/manuf)"
  [[ -n "$company" ]] && { echo "$company"; return; }
  echo "-"
}

resolve_hostname() {
  if command -v dig >/dev/null 2>&1; then
    dig +short -x "$1" @"$GATEWAY" 2>/dev/null | sed 's/\.$//' | awk 'NR==1 {print; exit}'
    return
  fi
  host "$1" 2>/dev/null \
    | awk '/domain name pointer/ {print $5; exit}' \
    | sed 's/\.$//' \
    || true
}

resolve_domain_answers() {
  local answers
  answers="$(
    dscacheutil -q host -a name "$1" 2>/dev/null \
      | awk '/^ip_address: / {print $2}'
  )"
  if [[ -n "$answers" ]]; then
    awk '!seen[$0]++' <<<"$answers"
    return
  fi
  host "$1" 2>/dev/null \
    | awk '/has address/ {print $4}' \
    | awk '!seen[$0]++' \
    || true
}
