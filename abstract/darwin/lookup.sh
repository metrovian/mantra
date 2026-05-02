lookup_mac() {
  arp -n "$1" | awk '/ at / {print $4; exit}'
}

lookup_company() {
  local prefix
  local oui_file

  prefix="$(tr '[:lower:]' '[:upper:]' <<<"$1" | awk -F: '{print $1 $2 $3}')"

  for oui_file in \
    /usr/share/ieee-data/oui.txt \
    /opt/homebrew/share/ieee-data/oui.txt \
    /usr/local/share/ieee-data/oui.txt; do
    if [[ -f "$oui_file" ]]; then
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
      ' "$oui_file"
      return
    fi
  done

  echo "-"
}
