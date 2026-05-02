check_dns() {
  local target
  local answer
  local status
  local dns_index
  local dns_server
  local dns_found

  target="github.com"
  answer="$(resolve_domain "$target")"
  status="fail"
  dns_index=1
  dns_found=0

  if [[ -n "${answer:-}" ]]; then
    status="ok"
  fi

  echo "DNS"
  echo "--------------------------------------------"

  while IFS= read -r dns_server; do
    [[ -z "$dns_server" ]] && continue

    dns_found=1
    echo "server${dns_index}   $dns_server"

    dns_index=$((dns_index + 1))
  done < <(resolve_dns_servers)

  if [[ "$dns_found" -eq 0 ]]; then
    echo "server    -"
  fi

  echo "target    $target"
  echo "answer    ${answer:--}"
  echo "status    $status"
  echo
}
