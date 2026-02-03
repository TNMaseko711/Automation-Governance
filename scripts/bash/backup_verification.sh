#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: backup_verification.sh -p backup_path [-a max_age_hours] [-l log_file] [--apply]

Defaults:
  - Dry-run mode (no checks executed).
  - max_age_hours: 24

Example:
  backup_verification.sh -p /mnt/backups --apply
USAGE
}

backup_path=""
max_age_hours=24
log_file="./logs/backup_verification_$(date +%Y%m%d).log"
apply=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--path)
      backup_path="$2"
      shift 2
      ;;
    -a|--max-age)
      max_age_hours="$2"
      shift 2
      ;;
    -l|--log)
      log_file="$2"
      shift 2
      ;;
    --apply)
      apply=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
 done

mkdir -p "$(dirname "$log_file")"

log() {
  printf '%s %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$1" | tee -a "$log_file"
}

if [[ -z "$backup_path" ]]; then
  log "ERROR: backup path is required."
  usage
  exit 1
fi

if [[ ! -d "$backup_path" ]]; then
  log "ERROR: backup path not found: $backup_path"
  exit 1
fi

log "Starting backup verification. apply=$apply path=$backup_path max_age_hours=$max_age_hours"

if ! $apply; then
  log "DRY-RUN: would verify newest backup age and checksums."
  exit 0
fi

latest_file=$(find "$backup_path" -type f -printf '%T@ %p\n' | sort -nr | head -n 1 | awk '{print $2}')
if [[ -z "$latest_file" ]]; then
  log "ERROR: No backup files found in $backup_path"
  exit 1
fi

latest_age_hours=$(( ( $(date +%s) - $(stat -c %Y "$latest_file") ) / 3600 ))
if [[ "$latest_age_hours" -gt "$max_age_hours" ]]; then
  log "ALERT: Latest backup $latest_file is ${latest_age_hours}h old"
else
  log "OK: Latest backup $latest_file is ${latest_age_hours}h old"
fi

if [[ -f "$backup_path/checksums.sha256" ]]; then
  log "Verifying checksums"
  (cd "$backup_path" && sha256sum -c checksums.sha256)
else
  log "WARNING: No checksum manifest found (checksums.sha256)"
fi

log "Backup verification complete."
