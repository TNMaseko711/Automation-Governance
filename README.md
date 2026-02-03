# IT Automation & Governance Toolkit

This repository demonstrates practical, operations-minded automation that an internal IT team would actually run. The focus is on repeatable, parameterized scripts with safe defaults, clear logging, and dry-run modes to reduce risk.

## Tooling

- **Bash** for Linux automation
- **PowerShell** for cross-platform operational workflows
- **Markdown** for documentation and usage guidance

## Scripts Overview

Each script defaults to **dry-run** mode. Use the `--apply` (Bash) or `-Apply` (PowerShell) switch to perform actions or write outputs.

### User Onboarding Automation
- **Bash:** `scripts/bash/user_onboarding.sh`
- **PowerShell:** `scripts/powershell/UserOnboarding.ps1`

**When to use:**
- Provision new hires during onboarding cycles
- Standardize account creation with consistent shells and group membership

**Risks if misused:**
- Creating accounts with incorrect group access
- Accidental creation of users in production systems

**How it reduces human error:**
- Uses a CSV-driven process to avoid typos
- Logs every action for audit trails

### Password Expiry Reporting
- **Bash:** `scripts/bash/password_expiry_report.sh`
- **PowerShell:** `scripts/powershell/PasswordExpiryReport.ps1`

**When to use:**
- Weekly compliance reporting for expiring credentials
- Preemptive notifications before access disruption

**Risks if misused:**
- Incorrectly targeting system accounts
- Overwriting reports without review

**How it reduces human error:**
- Parameterized minimum UID filtering
- Structured CSV output for consistent review

### Disk Space Monitoring
- **Bash:** `scripts/bash/disk_space_monitor.sh`
- **PowerShell:** `scripts/powershell/DiskSpaceMonitor.ps1`

**When to use:**
- Daily or hourly checks on servers
- Early warning before services fail from full disks

**Risks if misused:**
- Too-low thresholds causing alert fatigue
- Running without reviewing existing thresholds

**How it reduces human error:**
- Standardized threshold checking
- Logs and optional alert file output

### Backup Verification
- **Bash:** `scripts/bash/backup_verification.sh`
- **PowerShell:** `scripts/powershell/BackupVerification.ps1`

**When to use:**
- Daily verification of backup freshness
- Compliance checks to ensure recoverability

**Risks if misused:**
- False assurance if pointing to wrong backup path
- Ignoring checksum failures

**How it reduces human error:**
- Checks file age consistently
- Optional checksum verification for integrity

## Usage Examples

### Bash

```bash
# Dry-run onboarding
scripts/bash/user_onboarding.sh -i new_users.csv

# Apply onboarding
scripts/bash/user_onboarding.sh -i new_users.csv --apply

# Generate password expiry report
scripts/bash/password_expiry_report.sh -o /tmp/report.csv --apply

# Monitor disk usage and write alerts
scripts/bash/disk_space_monitor.sh -t 85 --apply

# Verify backups
scripts/bash/backup_verification.sh -p /mnt/backups --apply
```

### PowerShell

```powershell
# Dry-run onboarding
./scripts/powershell/UserOnboarding.ps1 -InputCsv new_users.csv

# Apply onboarding
./scripts/powershell/UserOnboarding.ps1 -InputCsv new_users.csv -Apply

# Generate password expiry report
./scripts/powershell/PasswordExpiryReport.ps1 -Output /tmp/report.csv -Apply

# Monitor disk usage and write alerts
./scripts/powershell/DiskSpaceMonitor.ps1 -Threshold 85 -Apply

# Verify backups
./scripts/powershell/BackupVerification.ps1 -BackupPath /mnt/backups -Apply
```

## Logging and Safe Defaults

- Each script writes a log file under `./logs/` by default.
- Dry-run mode is the default to prevent accidental changes.
- Outputs (reports/alerts) are only written when `--apply` / `-Apply` is provided.

## Interview Narrative

This toolkit showcases how automation reduces toil and risk:
- **Consistency:** parameterized inputs remove manual variance.
- **Auditability:** logs provide a timeline of decisions.
- **Safety:** dry-run defaults prevent unintended changes.
- **Governance:** reports and verification steps support compliance.
