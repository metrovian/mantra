lookup_company_prefix() {
  tr '[:lower:]' '[:upper:]' <<<"$1" | awk -F: '{print $1 $2 $3}'
}

lookup_format_mac() {
  local mac
  local -a octets

  mac="$1"
  IFS=: read -r -a octets <<<"$mac"

  if ((${#octets[@]} != 6)); then
    echo "$mac"
    return
  fi

  printf '%02x:%02x:%02x:%02x:%02x:%02x\n' \
    "$((16#${octets[0]}))" \
    "$((16#${octets[1]}))" \
    "$((16#${octets[2]}))" \
    "$((16#${octets[3]}))" \
    "$((16#${octets[4]}))" \
    "$((16#${octets[5]}))"
}

lookup_company_from_oui_file() {
  local prefix
  local oui_file

  prefix="$1"
  oui_file="$2"

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
}

lookup_company_from_oui_files() {
  local mac
  local prefix
  local oui_file
  local company

  mac="$1"
  prefix="$(lookup_company_prefix "$mac")"
  shift

  for oui_file in "$@"; do
    [[ -f "$oui_file" ]] || continue
    company="$(lookup_company_from_oui_file "$prefix" "$oui_file")"

    if [[ -n "$company" ]]; then
      echo "$company"
      return
    fi
  done
}

lookup_company_from_manuf_file() {
  local prefix

  prefix="$(lookup_company_prefix "$1")"

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
  ' "$2"
}

lookup_company_from_manuf_files() {
  local mac
  local manuf_file
  local company

  mac="$1"
  shift

  for manuf_file in "$@"; do
    [[ -f "$manuf_file" ]] || continue
    company="$(lookup_company_from_manuf_file "$mac" "$manuf_file")"

    if [[ -n "$company" ]]; then
      echo "$company"
      return
    fi
  done
}
