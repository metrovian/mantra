resolve_mdns_clean_name() {
  sed 's/\.$//' | sed 's/\.local$//'
}
