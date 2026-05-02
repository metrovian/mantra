PAIR_TITLE=""
PAIR_KEY_WIDTH=0
declare -a PAIR_KEYS=()
declare -a PAIR_VALUES=()

pair_reset() {
  PAIR_TITLE=""
  PAIR_KEY_WIDTH=0
  PAIR_KEYS=()
  PAIR_VALUES=()
}

pair_set_title() {
  PAIR_TITLE="$1"
}

pair_add() {
  local key
  local value

  key="$1"
  value="${2:-}"

  PAIR_KEYS+=("$key")
  PAIR_VALUES+=("$value")

  if ((${#key} > PAIR_KEY_WIDTH)); then
    PAIR_KEY_WIDTH=${#key}
  fi
}

pair_print() {
  local line_width
  local separator_width
  local index
  local line
  local key
  local value

  line_width=0

  for ((index = 0; index < ${#PAIR_KEYS[@]}; index++)); do
    key="${PAIR_KEYS[$index]}"
    value="${PAIR_VALUES[$index]}"
    line="${key}$(printf '%*s' "$((PAIR_KEY_WIDTH - ${#key} + 1))" '')${value}"

    if ((${#line} > line_width)); then
      line_width=${#line}
    fi
  done

  separator_width=${#PAIR_TITLE}

  if ((line_width > separator_width)); then
    separator_width=$line_width
  fi

  echo "$PAIR_TITLE"
  printf '%*s\n' "$separator_width" '' | tr ' ' '-'

  for ((index = 0; index < ${#PAIR_KEYS[@]}; index++)); do
    key="${PAIR_KEYS[$index]}"
    value="${PAIR_VALUES[$index]}"
    printf "%-${PAIR_KEY_WIDTH}s %s\n" "$key" "$value"
  done

  echo
}
