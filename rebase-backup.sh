#!/usr/bin/env bash

set -euo pipefail

verbose=0
source=""
webhook=""
retention=7
dest=""
LOG_FILE="/tmp/backup.log"
Usage() {
    echo "Usage: ${0##*/} -s SOURCE -d DEST -r RETENTION -w WEBHOOK [-v], [-l LOG_FILE] [-h]"
}

log() {
  local level="$1"
  shift

  local timestamp
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  local msg="$*"
  local log_line="[$timestamp] [$level] $msg"
  
  echo "$log_line" >> "$LOG_FILE" 2>/dev/null || {
    echo "[$timestamp] [ERROR] Cannot write to log file: $LOG_FILE" >&2
  }
  echo "$log_line"
  if [[ "$verbose" -eq 1 ]]; then
    echo "$log_line" >&2
  fi
}

alert_failure() {
  local msg="$1"
  log "ERROR" "$msg"

  if [[ -n "$webhook" ]]; then
    payload=$(printf '{"content":"Backup Failed: %s"}' "$msg")
    if ! curl -s -X POST -H 'Content-type: application/json' -d "$payload" "$webhook" >/dev/null 2>&1; then
      log "WARN" "Webhook notification failed to send"
    fi
  fi
}

tmp_file=$(mktemp -d)

cleanup() {
  if [[ -n "$tmp_file" && -d "$tmp_file" ]]; then
    rm -rf "$tmp_file"
  fi
}

trap cleanup EXIT

while getopts "s:d:r:w:vl:h" opt; do
 case "$opt" in
 s) source="$OPTARG" ;;
 d) dest="$OPTARG" ;;
 r) retention="$OPTARG" ;;
 w) webhook="$OPTARG" ;;
 v) verbose=1 ;;
 l) LOG_FILE="$OPTARG" ;;
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

log "INFO" "Cleaning up old backups"

mapfile -t backups < <(find "$dest" -maxdepth 1 -name "backup-*.tar.gz" -type f | sort -r || true)

if [[ "${#backups[@]}" -gt "$retention" ]]; then
  for backup in "${backups[@]:$retention}"; do
    log "INFO" "Removing old backup: $backup"
    rm -f "$backup"
  done
else
  log "WARN" "No old backups to remove"
fi

log "INFO" "Backup completed successfully"