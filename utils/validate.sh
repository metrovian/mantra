#!/usr/bin/env bash

validate_name() {
  case "$1" in
    ""|*[!a-zA-Z0-9._-]*)
      die "invalid name: $1"
      ;;
  esac
}
