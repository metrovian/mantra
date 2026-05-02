lookup_company_prefix() {
  tr '[:lower:]' '[:upper:]' <<<"$1" | awk -F: '{print $1 $2 $3}'
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
