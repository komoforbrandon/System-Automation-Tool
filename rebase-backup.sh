#!/usr/bin/env bash

set -euo pipefail

verbose=0
source=""
webhook=""
retention=7
dest=""

Usage() {
    echo "Usage: ${0##*/} -s SOURCE -d DEST -r RETENTION -w WEBHOOK [-v]"
}

log() {
  local level = "$1"
  shift

  local timestamp = $(date +"%Y-%m-%d %H:%M:%S")
  local msg="$*"
  echo "[$timestamp] [$level] $msg"
  if [[ "$verbose" -eq 1 ]]; then
    echo "[$timestamp] [$level] $msg" >&2
  fi
}

alert_failure() {
  local msg="$1"
  local timestamp = $(date +"%Y-%m-%d %H:%M:%S")
  log "ERROR" "$msg"

  if [[ -n "$webhook" ]]; then
    curl -X POST -H 'Content-type: application/json' \
      --data "{\"text\":\"Backup Failed: $msg\"}" \
      "$webhook" >/dev/null 2>&1 || true
  fi
}

tmp_file=$(mktemp -d)

cleanup() {
  if [[ -n "$tmp_file" && -d "$tmp_file" ]]; then
    rm -rf "$tmp_file"
  fi
}

trap cleanup EXIT

while getopts "s:d:r:w:vh" opt; do
 case "$opt" in
 s) source="$OPTARG" ;;
 d) dest="$OPTARG" ;;
 r) retention="$OPTARG" ;;
 w) webhook="$OPTARG" ;;
 v) verbose=1 ;;
 h) Usage; exit 0 ;;
 *) Usage >&2; exit 1 ;;
 esac
done

if [[ -z "$source" || -z "$dest" ]]; then
  Usage >&2
 exit 1
fi

if [[ ! "$retention" =~ ^[0-9]+$ ]] || [[ "$retention" -lt 1 ]]; then
  echo "Retention must be a positive integer" >&2
exit 1
fi

if [[ ! -d "$source" ]]; then
  echo "Source directory does not exist" >&2
  exit 1
fi  

mkdir -p "$dest"

timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
archive_name="backup-${timestamp}.tar.gz"
archive_path="${dest}/${archive_name}"

log "INFO" "Creating backup of $source to $archive_path"

if tar -czf "$archive_path" -C "$source" .; then
  log "INFO" "Backup archive created successfully: $archive_path"
else
  alert_failure "Failed to create backup archive: $archive_path"
  exit 1
fi
