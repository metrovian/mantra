ssh_fingerprint_from_key() {
  local key
  local output
  local type
  local hash
  key=$1
  output=$(printf '%s\n' "$key" | ssh-keygen -lf - -E sha256 2>/dev/null) || return 1
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

ssh_capture_key() {
  local hostname
  local output
  hostname=$1
  output="$({ ssh-keyscan -T 2 -t ed25519 "$hostname" 2>/dev/null || true; } \
    | awk 'NF >= 3 && $1 !~ /^#/ { print; exit }'
  )"
  if [ -n "$output" ]; then
    printf '%s\n' "$output"
    return 0
  fi
  output="$({ ssh-keyscan -T 2 "$hostname" 2>/dev/null || true; } \
    | awk 'NF >= 3 && $1 !~ /^#/ { print; exit }'
  )"
  if [ -n "$output" ]; then
    printf '%s\n' "$output"
    return 0
  fi
  return 1
}

ssh_key_body() {
  local key
  key=$1
  printf '%s\n' "${key#* }"
}
