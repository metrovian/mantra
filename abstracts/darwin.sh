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
    inspect_timeout_millis "$INSPECT_TIMEOUT"
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

inspect_timeout_millis() {
  awk -v timeout="$1" '
    BEGIN {
      value = int(timeout * 1000)
      if (value < 1) {
        value = 1
      }
      print value
    }
  '
}

inspect_now_millis() {
  perl -MTime::HiRes=time -e 'printf "%.0f\n", time() * 1000'
}

inspect_timeout_remaining() {
  local deadline
  local now
  local remaining
  deadline="$1"
  now="$(inspect_now_millis)"
  remaining=$((deadline - now))
  if ((remaining < 1)); then
    return 1
  fi
  awk -v value="$remaining" '
    BEGIN {
      printf "%.3f\n", value / 1000
    }
  '
}

inspect_mdns_browse_table() {
  local browse_deadline
  local browse_output
  local instance
  local line
  local remaining_timeout
  local resolve_output
  local address_output
  local host
  local ip
  browse_deadline=$(( $(inspect_now_millis) + $(inspect_timeout_millis \
    "$MDNS_BROWSE_TIMEOUT") ))
  remaining_timeout="$(inspect_timeout_remaining "$browse_deadline")" || return
  browse_output="$(
    inspect_capture_with_timeout \
      "$remaining_timeout" \
      dns-sd -B _workstation._tcp local.
  )"
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
    remaining_timeout="$(inspect_timeout_remaining "$browse_deadline")" || break
    resolve_output="$(
      inspect_capture_with_timeout \
        "$remaining_timeout" \
        dns-sd -L "$instance" _workstation._tcp local.
    )"
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
    remaining_timeout="$(inspect_timeout_remaining "$browse_deadline")" || break
    address_output="$(
      inspect_capture_with_timeout \
        "$remaining_timeout" \
        dns-sd -G v4 "$host"
    )"
    ip="$(
      awk '/ Add / {print $NF; exit}' <<<"$address_output"
    )"
    [[ -n "${ip:-}" ]] || continue
    printf '%s\t%s\n' "$ip" "$host"
  done <<<"$browse_output" | awk '!seen[$1]++'
}

inspect_capture_with_timeout() {
  local timeout
  local output_file
  local command_pid
  local timer_pid
  timeout="$1"
  shift
  output_file="$(mktemp)"
  "$@" >"$output_file" 2>/dev/null &
  command_pid=$!
  (
    sleep "$timeout"
    kill "$command_pid" 2>/dev/null || true
  ) &
  timer_pid=$!
  wait "$command_pid" 2>/dev/null || true
  kill "$timer_pid" 2>/dev/null || true
  wait "$timer_pid" 2>/dev/null || true
  cat "$output_file"
  rm -f "$output_file"
}

lookup_mac_table() {
  arp -an 2>/dev/null \
    | awk '
        function format_mac(value, octets, count, i, out) {
          count = split(tolower(value), octets, ":")
          out = ""
          for (i = 1; i <= count; i++) {
            if (length(octets[i]) == 1) {
              octets[i] = "0" octets[i]
            }
            out = out (i == 1 ? "" : ":") octets[i]
          }
          return out
        }
        / at / && $4 != "(incomplete)" {
          ip = $2
          gsub(/[()]/, "", ip)
          print ip "\t" format_mac($4)
        }
      ' \
    | awk '!seen[$1]++'
}

resolve_mdns_hostname() {
  inspect_capture_with_timeout \
    "$MDNS_RESOLVE_TIMEOUT" \
    dig +short -x "$1" @224.0.0.251 -p 5353 \
    | resolve_mdns_clean_name \
    | awk 'NR==1 {print; exit}'
}
