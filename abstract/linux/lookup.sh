lookup_mac() {
  ip neigh show "$1" | awk '/lladdr/ {print $5; exit}' | awk 'NR==1 {print; exit}'
}

lookup_company() {
  local company
  company="$(lookup_company_from_oui_files "$1" /usr/share/ieee-data/oui.txt)"
  [[ -n "$company" ]] && { echo "$company"; return; }
  echo "-"
}
