#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: disk_space_monitor.sh [-t threshold_percent] [-l log_file] [-o alert_file] [--apply]

Defaults:
  - Dry-run mode (no alert file written).
  - threshold_percent: 80
  - log_file: ./logs/disk_space_YYYYMMDD.log
  - alert_file: ./alerts/disk_space_alerts_YYYYMMDD.txt

Example:
  disk_space_monitor.sh -t 85 --apply
USAGE
}

threshold=80
log_file="./logs/disk_space_$(date +%Y%m%d).log"
alert_file="./alerts/disk_space_alerts_$(date +%Y%m%d).txt"
apply=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--threshold)
      threshold="$2"
      shift 2
      ;;
    -l|--log)
      log_file="$2"
      shift 2
      ;;
    -o|--output)
      alert_file="$2"
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

mkdir -p "$(dirname "$log_file")" "$(dirname "$alert_file")"

log() {
  printf '%s %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$1" | tee -a "$log_file"
}

log "Starting disk space monitor. apply=$apply threshold=${threshold}%"

if $apply; then
  : > "$alert_file"
fi

while IFS= read -r line; do
  filesystem=$(echo "$line" | awk '{print $1}')
  use_pct=$(echo "$line" | awk '{print $5}' | tr -d '%')
  mount_point=$(echo "$line" | awk '{print $6}')

  if [[ "$use_pct" -ge "$threshold" ]]; then
    message="ALERT: $filesystem at $mount_point is ${use_pct}% full"
    if $apply; then
      echo "$message" >> "$alert_file"
    else
      log "DRY-RUN: would write '$message'"
    fi
  fi
 done < <(df -P | tail -n +2)

if $apply; then
  log "Alerts written to $alert_file"
else
  log "Dry-run complete. Use --apply to write alerts."
fi
