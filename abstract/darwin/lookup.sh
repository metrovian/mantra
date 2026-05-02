lookup_mac() {
  local mac
  local o1
  local o2
  local o3
  local o4
  local o5
  local o6

  mac="$(arp -n "$1" | awk '/ at / {print $4; exit}')"

  if [[ -z "$mac" ]]; then
    return
  fi

  IFS=: read -r o1 o2 o3 o4 o5 o6 <<<"$mac"

  if [[ -z "$o1" || -z "$o2" || -z "$o3" || -z "$o4" || -z "$o5" || -z "$o6" ]]; then
    echo "$mac"
    return
  fi

  printf '%02x:%02x:%02x:%02x:%02x:%02x\n' \
    "$((16#$o1))" \
    "$((16#$o2))" \
    "$((16#$o3))" \
    "$((16#$o4))" \
    "$((16#$o5))" \
    "$((16#$o6))"
}

lookup_company() {
  local prefix
  local oui_file
  local company

  prefix="$(tr '[:lower:]' '[:upper:]' <<<"$1" | awk -F: '{print $1 $2 $3}')"

  for oui_file in \
    /usr/share/ieee-data/oui.txt \
    /opt/homebrew/share/ieee-data/oui.txt \
    /usr/local/share/ieee-data/oui.txt; do
    if [[ -f "$oui_file" ]]; then
      company="$(
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
      )"

      if [[ -n "$company" ]]; then
        echo "$company"
        return
      fi
    fi
  done

  for oui_file in \
    /opt/homebrew/etc/wireshark/manuf \
    /usr/local/etc/wireshark/manuf \
    /Applications/Wireshark.app/Contents/Resources/share/wireshark/manuf; do
    if [[ -f "$oui_file" ]]; then
      company="$(
        awk -v prefix="$prefix" '
          BEGIN {
            needle = substr(prefix, 1, 2) ":" substr(prefix, 3, 2) ":" substr(prefix, 5, 2)
          }
          $1 == needle {
            if ($3 != "") {
              $1 = ""
              $2 = ""
              sub(/^[ \t]+/, "")
              sub(/[ \t]+#.*$/, "")
              print
              exit
            }

            print $2
            exit
          }
        ' "$oui_file"
      )"

      if [[ -n "$company" ]]; then
        echo "$company"
        return
      fi
    fi
  done

  echo "-"
}
