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

ssh_capture_key() {
  local hostname
  local output
  hostname=$1
  output="$(ssh-keyscan -T 2 "$hostname" 2>/dev/null)" || return 1
  grep -m 1 -E '^[^#[:space:]]+[[:space:]]+ssh-ed25519[[:space:]]' <<<"$output" \
    || grep -m 1 -E '^[^#[:space:]]+[[:space:]]+ecdsa-sha2-' <<<"$output" \
    || grep -m 1 -E '^[^#[:space:]]+[[:space:]]+ssh-rsa[[:space:]]' <<<"$output" \
    || awk 'NF >= 3 && $1 !~ /^#/ { print; found = 1; exit }
      END { exit !found }' <<<"$output"
}
