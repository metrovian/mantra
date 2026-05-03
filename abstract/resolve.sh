resolve_domain() {
  resolve_domain_answers "$1" | awk 'NR==1 {print; exit}' || true
}
