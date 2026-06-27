host_exists() {
  local alias
  alias=$1
  if [ ! -f "$MANTRA_HOSTS_FILE" ]; then
    return 1
  fi
  awk -F '[ ]+' -v alias="$alias" \
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
  local alias
  local user
  local hostname
  local fingerprint
  alias=$1
  user=$2
  hostname=$3
  fingerprint=${4:-}
  printf '%s %s %s %s\n' \
    "$alias" \
    "$user" \
    "$hostname" \
    "$fingerprint" \
    >>"$MANTRA_HOSTS_FILE"
}

host_replace() {
  local target_file
  local callback
  local output_file
  local target_dir
  local target_name
  target_file=$1
  callback=$2
  shift 2
  case "$target_file" in
    */*) target_dir=${target_file%/*} ;;
    *) target_dir=. ;;
  esac
  target_name=${target_file##*/}
  output_file=$(mktemp "$target_dir/.${target_name}.XXXXXX")
  if ! "$callback" "$@" >"$output_file"; then
    rm -f "$output_file"
    return 1
  fi
  if cmp -s "$target_file" "$output_file"; then
    rm -f "$output_file"
  elif ! mv "$output_file" "$target_file"; then
    rm -f "$output_file"
    return 1
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

host_sync_hosts() {
  local records
  local alias
  local user
  local hostname
  local fingerprint
  local matched_host
  records=${1:-}
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
  done <"$MANTRA_HOSTS_FILE"
}

host_sync() {
  local records
  records=${1:-}
  [ -n "$records" ] || return 0
  host_replace "$MANTRA_HOSTS_FILE" host_sync_hosts "$records"
}

host_remove_hosts() {
  local alias
  local host_alias
  local user
  local hostname
  local fingerprint
  alias=$1
  while IFS=' ' read -r host_alias user hostname fingerprint; do
    if [ -z "$host_alias" ]; then
      printf '\n'
      continue
    fi
    if [ "$host_alias" = "$alias" ]; then
      continue
    fi
    printf '%s %s %s %s\n' \
      "$host_alias" \
      "$user" \
      "$hostname" \
      "$fingerprint"
  done <"$MANTRA_HOSTS_FILE"
}

host_remove_known_hosts() {
  local alias
  local line
  local host_field
  local key_alias
  alias=$1
  key_alias=$(host_key_alias "$alias")
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
  done <"$MANTRA_KNOWN_HOSTS_FILE"
}

host_remove() {
  local alias
  alias=$1
  host_replace "$MANTRA_HOSTS_FILE" host_remove_hosts "$alias"
  host_replace "$MANTRA_KNOWN_HOSTS_FILE" host_remove_known_hosts "$alias"
}

host_write_ssh_config() {
  local output
  local alias
  local user
  local hostname
  local key_alias
  output=$1
  if [ ! -f "$MANTRA_KNOWN_HOSTS_FILE" ]; then
    : >"$MANTRA_KNOWN_HOSTS_FILE"
  fi
  : >"$output"
  while IFS=' ' read -r alias user hostname _; do
    [ -n "$alias" ] || continue
    key_alias=$(host_key_alias "$alias")
    cat >>"$output" <<EOF2
Host $alias
  HostName $hostname
  User $user
  HostKeyAlias $key_alias
  UserKnownHostsFile $MANTRA_KNOWN_HOSTS_FILE

EOF2
  done <"$MANTRA_HOSTS_FILE"
}

host_prepare_connection() {
  local alias
  local hostname
  local key
  local key_alias
  local known_key
  local fingerprint
  alias=$1
  hostname=$2
  key=$(ssh_capture_key "$hostname") || return 1
  fingerprint=$(ssh_fingerprint_from_key "$key") || return 1
  [ -n "$fingerprint" ] || return 1
  key_alias=$(host_key_alias "$alias")
  known_key="$key_alias ${key#* }"
  if ! grep -Fqx "$known_key" "$MANTRA_KNOWN_HOSTS_FILE" 2>/dev/null; then
    printf '%s\n' "$known_key" >>"$MANTRA_KNOWN_HOSTS_FILE"
  fi
  printf '%s\n' "$fingerprint"
}
