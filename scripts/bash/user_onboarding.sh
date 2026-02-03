#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: user_onboarding.sh -i users.csv [-g default_groups] [-s shell] [-l log_file] [--apply]

Defaults:
  - Dry-run mode (no changes made).
  - Groups: empty (no extra groups)
  - Shell: /bin/bash

CSV format:
  username,full_name,primary_group,extra_groups

Example:
  user_onboarding.sh -i new_users.csv -g "devops" -s /bin/bash --apply
USAGE
}

log_file="./logs/user_onboarding_$(date +%Y%m%d).log"
apply=false
input=""
default_groups=""
user_shell="/bin/bash"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--input)
      input="$2"
      shift 2
      ;;
    -g|--groups)
      default_groups="$2"
      shift 2
      ;;
    -s|--shell)
      user_shell="$2"
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

if [[ -z "$input" ]]; then
  log "ERROR: Input CSV is required."
  usage
  exit 1
fi

if [[ ! -f "$input" ]]; then
  log "ERROR: Input CSV not found: $input"
  exit 1
fi

log "Starting user onboarding. apply=$apply input=$input"

while IFS=, read -r username full_name primary_group extra_groups; do
  [[ -z "$username" || "$username" == "username" ]] && continue

  final_extra_groups="$extra_groups"
  if [[ -n "$default_groups" ]]; then
    if [[ -n "$final_extra_groups" ]]; then
      final_extra_groups="$final_extra_groups,$default_groups"
    else
      final_extra_groups="$default_groups"
    fi
  fi

  if id "$username" &>/dev/null; then
    log "User exists: $username. Skipping create."
    continue
  fi

  cmd=(useradd -m -s "$user_shell" -c "$full_name")
  if [[ -n "$primary_group" ]]; then
    cmd+=( -g "$primary_group" )
  fi
  if [[ -n "$final_extra_groups" ]]; then
    cmd+=( -G "$final_extra_groups" )
  fi
  cmd+=( "$username" )

  if $apply; then
    log "Creating user: $username"
    "${cmd[@]}"
  else
    log "DRY-RUN: ${cmd[*]}"
  fi

done < "$input"

log "Completed user onboarding."
