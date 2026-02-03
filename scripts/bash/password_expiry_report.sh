#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: password_expiry_report.sh [-o report.csv] [-m min_uid] [-l log_file] [--apply]

Defaults:
  - Dry-run mode (no report written).
  - Output: ./reports/password_expiry_YYYYMMDD.csv
  - min_uid: 1000

Example:
  password_expiry_report.sh -o /tmp/report.csv --apply
USAGE
}

output="./reports/password_expiry_$(date +%Y%m%d).csv"
log_file="./logs/password_expiry_$(date +%Y%m%d).log"
min_uid=1000
apply=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--output)
      output="$2"
      shift 2
      ;;
    -m|--min-uid)
      min_uid="$2"
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

mkdir -p "$(dirname "$log_file")" "$(dirname "$output")"

log() {
  printf '%s %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$1" | tee -a "$log_file"
}

log "Starting password expiry report. apply=$apply min_uid=$min_uid"

if ! command -v chage >/dev/null 2>&1; then
  log "ERROR: chage command not found."
  exit 1
fi

if $apply; then
  echo "username,last_change,expires" > "$output"
fi

while IFS=: read -r username _ uid _ _ _ _; do
  [[ "$uid" -lt "$min_uid" ]] && continue

  if $apply; then
    expires=$(chage -l "$username" | awk -F': ' '/Password expires/{print $2}')
    last_change=$(chage -l "$username" | awk -F': ' '/Last password change/{print $2}')
    echo "$username,$last_change,$expires" >> "$output"
  else
    log "DRY-RUN: would inspect $username and append to report"
  fi

done < /etc/passwd

if $apply; then
  log "Report written to $output"
else
  log "Dry-run complete. Use --apply to write the report."
fi
