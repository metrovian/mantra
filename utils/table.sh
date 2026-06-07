TABLE_COLUMN_COUNT=0
declare -a TABLE_HEADERS=()
declare -a TABLE_WIDTHS=()
declare -a TABLE_ROWS=()

table_reset() {
  TABLE_COLUMN_COUNT=0
  TABLE_HEADERS=()
  TABLE_WIDTHS=()
  TABLE_ROWS=()
}

table_set_headers() {
  local index
  local header
  TABLE_COLUMN_COUNT=$#
  TABLE_HEADERS=("$@")
  TABLE_WIDTHS=()
  for ((index = 0; index < TABLE_COLUMN_COUNT; index++)); do
    header="${TABLE_HEADERS[$index]}"
    TABLE_WIDTHS[index]=${#header}
  done
}

table_add_row() {
  local index
  local value
  local row
  row=""
  for ((index = 0; index < TABLE_COLUMN_COUNT; index++)); do
    value="${1:-}"
    if ((index > 0)); then
      row+=$'\t'
    fi
    row+="$value"
    if ((${#value} > TABLE_WIDTHS[index])); then
      TABLE_WIDTHS[index]=${#value}
    fi
    shift
  done
  TABLE_ROWS+=("$row")
}

table_term_cols() {
  local size
  local cols
  if [ -r /dev/tty ]; then
    size="$(stty size </dev/tty 2>/dev/null || true)"
  else
    size="$(stty size 2>/dev/null || true)"
  fi
  [ -n "$size" ] || return 1
  read -r _ cols <<<"$size"
  [ -n "${cols:-}" ] || return 1
  case "$cols" in
    *[!0-9]*) return 1 ;;
  esac
  printf '%s\n' "$cols"
}

table_fit_terminal() {
  local cols
  local width
  local overflow
  local index
  local min_width
  local margin
  if [ ! -t 1 ]; then
    return 0
  fi
  if ((TABLE_COLUMN_COUNT == 0)); then
    return 0
  fi
  cols="$(table_term_cols || true)"
  [ -n "$cols" ] || return 0
  width=0
  for ((index = 0; index < TABLE_COLUMN_COUNT; index++)); do
    width=$((width + TABLE_WIDTHS[index]))
  done
  width=$((width + TABLE_COLUMN_COUNT - 1))
  margin=1
  overflow=$((width + margin - cols))
  if ((overflow <= 0)); then
    return 0
  fi
  index=$((TABLE_COLUMN_COUNT - 1))
  min_width=${#TABLE_HEADERS[$index]}
  if ((min_width < 3)); then
    min_width=3
  fi
  if ((TABLE_WIDTHS[index] - overflow < min_width)); then
    TABLE_WIDTHS[index]=$min_width
  else
    TABLE_WIDTHS[index]=$((TABLE_WIDTHS[index] - overflow))
  fi
}

table_truncate() {
  local value
  local width
  value=$1
  width=$2
  if ((${#value} <= width)); then
    printf '%s\n' "$value"
  elif ((width <= 3)); then
    printf '%.*s\n' "$width" "..."
  else
    printf '%s...\n' "${value:0:$((width - 3))}"
  fi
}

table_separator_cell() {
  local index
  index=$1
  printf '%*s' "${TABLE_WIDTHS[$index]}" '' | tr ' ' '-'
  if ((index == TABLE_COLUMN_COUNT - 1)); then
    printf '%s\n' '-'
  else
    printf ' '
  fi
}

table_print_cell() {
  local index
  local value
  index=$1
  value=$2
  value="$(table_truncate "$value" "${TABLE_WIDTHS[$index]}")"
  if ((index == TABLE_COLUMN_COUNT - 1)); then
    printf '%s\n' "$value"
  else
    printf '%-*s ' "${TABLE_WIDTHS[$index]}" "$value"
  fi
}

table_print_row() {
  local index
  local value
  local -a fields
  fields=("$@")
  for ((index = 0; index < TABLE_COLUMN_COUNT; index++)); do
    value="${fields[$index]:-}"
    table_print_cell "$index" "$value"
  done
}

table_print_separator() {
  local index
  for ((index = 0; index < TABLE_COLUMN_COUNT; index++)); do
    table_separator_cell "$index"
  done
}

table_print() {
  local row
  local -a fields
  table_fit_terminal
  table_print_row "${TABLE_HEADERS[@]}"
  table_print_separator
  if [ "${#TABLE_ROWS[@]}" -eq 0 ]; then
    return 0
  fi
  for row in "${TABLE_ROWS[@]}"; do
    IFS=$'\t' read -r -a fields <<<"$row"
    table_print_row "${fields[@]}"
  done
}
