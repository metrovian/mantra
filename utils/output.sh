output_log() {
  printf '%s\n' "$*"
}

output_die() {
  printf '%s\n' "$*" >&2
  exit 1
}
