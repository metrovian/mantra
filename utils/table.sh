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
    TABLE_WIDTHS[$index]=${#header}
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
    if ((${#value} > TABLE_WIDTHS[$index])); then
      TABLE_WIDTHS[$index]=${#value}
    fi
    shift
  done
  TABLE_ROWS+=("$row")
}

table_print() {
  local format
  local separator_line
  local row
  local index
  local value
  local -a fields
  format=""
  separator_line=""
  for ((index = 0; index < TABLE_COLUMN_COUNT; index++)); do
    if ((index < TABLE_COLUMN_COUNT - 1)); then
      format+="%-${TABLE_WIDTHS[$index]}s "
      separator_line+="$(printf '%*s' "${TABLE_WIDTHS[$index]}" '' | tr ' ' '-') "
    else
      format+="%s"
      separator_line+="$(printf '%*s' "${TABLE_WIDTHS[$index]}" '' | tr ' ' '-')"
    fi
  done
  format+=$'\n'
  separator_line+="-"
  fields=("${TABLE_HEADERS[@]}")
  printf "$format" "${fields[@]}"
  printf "%s\n" "$separator_line"
  for row in "${TABLE_ROWS[@]}"; do
    IFS=$'\t' read -r -a fields <<<"$row"
    for ((index = 0; index < TABLE_COLUMN_COUNT; index++)); do
      value="${fields[$index]:-}"
      fields[$index]="$value"
    done
    printf "$format" "${fields[@]}"
  done
}
