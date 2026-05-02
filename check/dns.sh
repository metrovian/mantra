check_dns() {
  local target
  local answer

  target="naver.com"
  answer="$(resolve_domain "$target")"

  echo "DNS"
  echo "--------------------------------------------"

  echo "name      $target"
  echo "answer    ${answer:--}"
  echo
}
