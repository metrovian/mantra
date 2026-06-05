ssh_fingerprint_from_key() {
  local key
  local output
  local type
  local hash
  key=$1
  output=$(printf '%s\n' "$key" | ssh-keygen -lf - -E sha256 2>/dev/null) || return 1
  type=${output##* }
  type=${type#(}
  type=${type%)}
  type=$(printf '%s' "$type" | tr '[:upper:]' '[:lower:]')
  hash=$(printf '%s\n' "$output" | awk 'NR == 1 { print $2 }')
  printf '%s:%s\n' "$type" "$hash"
}

ssh_scan_key() {
  local hostname
  hostname=$1
  shift
  ssh-keyscan -T 2 "$@" "$hostname" 2>/dev/null \
    | awk 'NF >= 3 && $1 !~ /^#/ && !found { print; found = 1 }
      END { exit !found }'
}

ssh_capture_key() {
  local hostname
  hostname=$1
  ssh_scan_key "$hostname" -t ed25519 || ssh_scan_key "$hostname"
}

ssh_key_body() {
  local key
  key=$1
  printf '%s\n' "${key#* }"
}
