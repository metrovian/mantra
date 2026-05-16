#!/usr/bin/env bash

log() {
  printf '%s\n' "$*"
}

die() {
  printf '%s\n' "$*" >&2
  exit 1
}
