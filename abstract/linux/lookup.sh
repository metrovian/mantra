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
