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

inspect_host_reachable() {
  ping -c 1 -W "$(
    awk -v timeout="$INSPECT_TIMEOUT" '
      BEGIN {
        value = int(timeout * 1000)
        if (value < 1) {
          value = 1
        }
        print value
      }
    '
  )" "$1"
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

inspect_mdns_browse_table() {
  local browse_output
  local browse_file
  local browse_pid
  local instance
  local line
  local resolve_output
  local resolve_file
  local resolve_pid
  local address_output
  local address_file
  local address_pid
  local host
  local ip
  browse_file="$(mktemp)"
  dns-sd -B _workstation._tcp local. >"$browse_file" 2>/dev/null &
  browse_pid=$!
  sleep "$MDNS_BROWSE_TIMEOUT"
  kill "$browse_pid" 2>/dev/null || true
  wait "$browse_pid" 2>/dev/null || true
  browse_output="$(cat "$browse_file")"
  rm -f "$browse_file"
  while IFS= read -r line; do
    [[ "$line" == *" Add "* ]] || continue
    instance="$(
      awk '
        / Add / {
          out = $7
          for (i = 8; i <= NF; i++) {
            out = out " " $i
          }
          print out
        }
      ' <<<"$line"
    )"
    [[ -n "${instance:-}" ]] || continue
    resolve_file="$(mktemp)"
    dns-sd -L "$instance" _workstation._tcp local. >"$resolve_file" 2>/dev/null &
    resolve_pid=$!
    sleep "$MDNS_RESOLVE_TIMEOUT"
    kill "$resolve_pid" 2>/dev/null || true
    wait "$resolve_pid" 2>/dev/null || true
    resolve_output="$(cat "$resolve_file")"
    rm -f "$resolve_file"
    host="$(
      awk '
        /can be reached at/ {
          sub(/^.*can be reached at /, "")
          sub(/:[0-9][0-9]*[[:space:]].*$/, "")
          print
          exit
        }
      ' <<<"$resolve_output" | resolve_mdns_clean_name
    )"
    [[ -n "${host:-}" ]] || continue
    address_file="$(mktemp)"
    dns-sd -G v4 "$host" >"$address_file" 2>/dev/null &
    address_pid=$!
    sleep "$MDNS_RESOLVE_TIMEOUT"
    kill "$address_pid" 2>/dev/null || true
    wait "$address_pid" 2>/dev/null || true
    address_output="$(cat "$address_file")"
    rm -f "$address_file"
    ip="$(
      awk '/ Add / {print $NF; exit}' <<<"$address_output"
    )"
    [[ -n "${ip:-}" ]] || continue
    printf '%s\t%s\n' "$ip" "$host"
  done <<<"$browse_output" | awk '!seen[$1]++'
}

resolve_mdns_hostname() {
  dig +short -x "$1" @224.0.0.251 -p 5353 2>/dev/null \
    | resolve_mdns_clean_name \
    | awk 'NR==1 {print; exit}'
}
