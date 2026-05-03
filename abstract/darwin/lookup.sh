lookup_mac() {
  local mac

  mac="$(arp -n "$1" | awk '/ at / {print $4; exit}')"
  [[ -n "$mac" ]] && lookup_format_mac "$mac"
}

lookup_company() {
  local company

  company="$(lookup_company_from_oui_files "$1" \
    /usr/share/ieee-data/oui.txt \
    /opt/homebrew/share/ieee-data/oui.txt \
    /usr/local/share/ieee-data/oui.txt)"

  if [[ -n "$company" ]]; then
    echo "$company"
    return
  fi

  company="$(lookup_company_from_manuf_files "$1" \
    /opt/homebrew/etc/wireshark/manuf \
    /usr/local/etc/wireshark/manuf \
    /Applications/Wireshark.app/Contents/Resources/share/wireshark/manuf)"

  if [[ -n "$company" ]]; then
    echo "$company"
    return
  fi

  echo "-"
}
