lookup_mac() {
  ip neigh show "$1" | awk '/lladdr/ {print $5; exit}'
}

lookup_company() {
  local prefix
  local company

  prefix="$(lookup_company_prefix "$1")"

  if [[ -f /usr/share/ieee-data/oui.txt ]]; then
    company="$(lookup_company_from_oui_file "$prefix" /usr/share/ieee-data/oui.txt)"

    if [[ -n "$company" ]]; then
      echo "$company"
      return
    fi
  fi

  echo "-"
}
