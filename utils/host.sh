host_exists() {
  if [ ! -f "$MANTRA_HOSTS_FILE" ]; then
    return 1
  fi
  awk -F '[ ]+' -v alias="$1" \
    '$1 == alias { found = 1 } END { exit !found }' "$MANTRA_HOSTS_FILE"
}

host_each() {
  local callback
  local alias
  local user
  local hostname
  local fingerprint
  callback=$1
  shift
  if [ ! -f "$MANTRA_HOSTS_FILE" ]; then
    return 0
  fi
  while IFS=' ' read -r alias user hostname fingerprint; do
    [ -n "$alias" ] || continue
    "$callback" "$alias" "$user" "$hostname" "$fingerprint" "$@"
  done <"$MANTRA_HOSTS_FILE"
}

host_add() {
  printf '%s %s %s %s\n' \
    "$1" \
    "$2" \
    "$3" \
    "${4:-}" \
    >>"$MANTRA_HOSTS_FILE"
}

host_replace() {
  if cmp -s "$1" "$2"; then
    rm -f "$2"
  else
    mv "$2" "$1"
  fi
}

host_record_for() {
  local records
  local field
  local value
  records=${1:-}
  field=$2
  value=$3
  awk -F '\t' -v field="$field" -v value="$value" '
    $1 != "" && $field == value {
      print $1
      exit
    }
  ' <<<"$records"
}

host_key_alias() {
  printf 'mantra-%s\n' "$1"
}

host_sync() {
  local records
  local output_file
  local known_hosts_output
  local alias
  local user
  local hostname
  local fingerprint
  local matched_host
  local line
  local host_field
  local key
  records=${1:-}
  [ -n "$records" ] || return 0
  output_file=$(mktemp "${TMPDIR:-/tmp}/mantra.XXXXXX")
  while IFS=' ' read -r alias user hostname fingerprint; do
    if [ -z "$alias" ]; then
      printf '\n'
      continue
    fi
    matched_host=
    if [ -n "$fingerprint" ] && [ "$fingerprint" != "-" ]; then
      matched_host=$(host_record_for "$records" 2 "$fingerprint")
    fi
    if [ -n "$matched_host" ]; then
      hostname=$matched_host
    fi
    printf '%s %s %s %s\n' "$alias" "$user" "$hostname" "$fingerprint"
  done <"$MANTRA_HOSTS_FILE" >"$output_file"
  host_replace "$MANTRA_HOSTS_FILE" "$output_file"
  known_hosts_output=$(mktemp "${TMPDIR:-/tmp}/mantra.XXXXXX")
  while IFS= read -r line; do
    if [ -z "$line" ] || [ "${line#\#}" != "$line" ]; then
      printf '%s\n' "$line"
      continue
    fi
    host_field=${line%% *}
    key=${line#* }
    if [ "$host_field" = "$line" ]; then
      printf '%s\n' "$line"
      continue
    fi
    case "$host_field" in
      mantra-*)
        printf '%s\n' "$line"
        continue
        ;;
    esac
    matched_host=$(host_record_for "$records" 3 "$key")
    if [ -n "$matched_host" ]; then
      host_field=$matched_host
    fi
    printf '%s %s\n' "$host_field" "$key"
  done <"$MANTRA_KNOWN_HOSTS_FILE" >"$known_hosts_output"
  host_replace "$MANTRA_KNOWN_HOSTS_FILE" "$known_hosts_output"
}

host_remove() {
  local output
  local known_hosts_output
  local host_alias
  local user
  local hostname
  local fingerprint
  local line
  local host_field
  local key_alias
  key_alias=$(host_key_alias "$1")
  output=$(mktemp "${TMPDIR:-/tmp}/mantra.XXXXXX")
  while IFS=' ' read -r host_alias user hostname fingerprint; do
    if [ -z "$host_alias" ]; then
      printf '\n' >>"$output"
      continue
    fi
    if [ "$host_alias" = "$1" ]; then
      continue
    fi
    printf '%s %s %s %s\n' \
      "$host_alias" \
      "$user" \
      "$hostname" \
      "$fingerprint" \
      >>"$output"
  done <"$MANTRA_HOSTS_FILE"
  host_replace "$MANTRA_HOSTS_FILE" "$output"
  known_hosts_output=$(mktemp "${TMPDIR:-/tmp}/mantra.XXXXXX")
  while IFS= read -r line; do
    if [ -z "$line" ] || [ "${line#\#}" != "$line" ]; then
      printf '%s\n' "$line"
      continue
    fi
    host_field=${line%% *}
    if [ "$host_field" = "$key_alias" ]; then
      continue
    fi
    printf '%s\n' "$line"
  done <"$MANTRA_KNOWN_HOSTS_FILE" >"$known_hosts_output"
  host_replace "$MANTRA_KNOWN_HOSTS_FILE" "$known_hosts_output"
}

host_write_ssh_config() {
  local output
  local alias
  local user
  local hostname
  output=$1
  if [ ! -f "$MANTRA_KNOWN_HOSTS_FILE" ]; then
    : >"$MANTRA_KNOWN_HOSTS_FILE"
  fi
  : >"$output"
  while IFS=' ' read -r alias user hostname _; do
    [ -n "$alias" ] || continue
    cat >>"$output" <<EOF2
Host $alias
  HostName $hostname
  User $user
  HostKeyAlias $(host_key_alias "$alias")
  UserKnownHostsFile $MANTRA_KNOWN_HOSTS_FILE

EOF2
  done <"$MANTRA_HOSTS_FILE"
}

host_prepare_connection() {
  local key
  local known_key
  local fingerprint
  key=$(ssh_capture_key "$2") || return 1
  fingerprint=$(ssh_fingerprint_from_key "$key") || return 1
  [ -n "$fingerprint" ] || return 1
  known_key="$(host_key_alias "$1") ${key#* }"
  if ! grep -Fqx "$known_key" "$MANTRA_KNOWN_HOSTS_FILE" 2>/dev/null; then
    printf '%s\n' "$known_key" >>"$MANTRA_KNOWN_HOSTS_FILE"
  fi
  printf '%s\n' "$fingerprint"
}
