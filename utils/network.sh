network_prepare_context() {
  inspect_network
  [[ -n "${GATEWAY:-}" && -n "${IFACE:-}" && -n "${ME:-}" \
    && -n "${PREFIX:-}" && -n "${SUBNET_CIDR:-}" ]] || return 1
}

network_local() {
  pair_reset
  pair_set_title "LOCAL"
  pair_add "time" "$(date '+%Y-%m-%d %H:%M:%S %Z')"
  pair_add "iface" "$IFACE"
  pair_add "me" "$ME"
  pair_add "gateway" "$GATEWAY"
  pair_add "subnet" "$SUBNET_CIDR"
  pair_print
}

network_neighbors_records() {
  local ip
  local ssh
  local fingerprint
  local key
  while IFS=$'\t' read -r ip ssh; do
    [[ -n "${ip:-}" ]] || continue
    fingerprint='-'
    key='-'
    if [[ -n "${ssh:-}" ]]; then
      IFS=$'\t' read -r fingerprint key <<<"$(network_ssh_details "$ssh")"
    fi
    fingerprint=${fingerprint:--}
    key=${key:--}
    printf '%s\t%s\t%s\n' "$ip" "$fingerprint" "$key"
  done < <(
    network_neighbors_scan "$@" | network_neighbors_parse
  )
}

network_neighbors_print() {
  local ip
  local fingerprint
  local key
  local records
  records=${1:-}
  table_reset
  table_set_headers "IP" "SSH"
  while IFS=$'\t' read -r ip fingerprint key; do
    [[ -n "${ip:-}" ]] || continue
    table_add_row "$ip" "$fingerprint"
  done <<<"$records"
  table_print
}

network_neighbors_scan() {
  sudo nmap \
    -n \
    -p 22 \
    --exclude "$ME" \
    "$@" 2>/dev/null || true
}

network_neighbors_parse() {
  awk '
    function emit() {
      if (ip == "") {
        return
      }
      print ip "\t" ssh
    }
    /^Nmap scan report for / {
      emit()
      ip = $NF
      ssh = ""
      next
    }
    /^22\/tcp[[:space:]]+open[[:space:]]+ssh$/ {
      ssh = ip
      next
    }
    /^Nmap done:/ {
      emit()
      ip = ""
    }
    END {
      emit()
    }
  '
}

network_fingerprint_from_key() {
  local key_line
  local output
  local type
  local hash
  key_line=$1
  output=$(printf '%s\n' "$key_line" | ssh-keygen -lf - -E sha256 2>/dev/null) || return 1
  [ -n "$output" ] || return 1
  type=${output##* }
  type=${type#(}
  type=${type%)}
  type=$(printf '%s' "$type" | tr '[:upper:]' '[:lower:]')
  hash=$(printf '%s\n' "$output" | awk 'NR == 1 { print $2 }')
  [ -n "$type" ] || return 1
  [ -n "$hash" ] || return 1
  printf '%s:%s\n' "$type" "$hash"
}

network_ssh_details() {
  local ip
  local key_line
  local fingerprint
  local key
  ip=$1
  key_line="$({ ssh-keyscan -T 2 -t ed25519 "$ip" 2>/dev/null || true; } \
    | awk 'NF >= 3 && $1 !~ /^#/ { print; exit }'
  )"
  if [[ -z "$key_line" ]]; then
    key_line="$({ ssh-keyscan -T 2 "$ip" 2>/dev/null || true; } \
      | awk 'NF >= 3 && $1 !~ /^#/ { print; exit }'
    )"
  fi
  if [[ -z "$key_line" ]]; then
    printf '%s\t%s\n' '-' '-'
    return
  fi
  fingerprint="$(network_fingerprint_from_key "$key_line" || true)"
  key=${key_line#* }
  printf '%s\t%s\n' "${fingerprint:--}" "$key"
}
