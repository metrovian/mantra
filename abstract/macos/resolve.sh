resolve_hostname() {
  host "$1" 2>/dev/null \
    | awk '/domain name pointer/ {print $5; exit}' \
    | sed 's/\.$//' \
    || true
}

resolve_dns_servers() {
  scutil --dns 2>/dev/null \
    | awk '/nameserver\[[0-9]+\]/ {print $3}'
}

resolve_domain() {
  dscacheutil -q host -a name "$1" 2>/dev/null \
    | awk '/^ip_address: / {print $2; exit}' \
    || host "$1" 2>/dev/null \
      | awk '/has address/ {print $4; exit}' \
      || true
}
