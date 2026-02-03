[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$BackupPath,
    [int]$MaxAgeHours = 24,
    [string]$LogFile = ("./logs/backup_verification_{0:yyyyMMdd}.log" -f (Get-Date)),
    [switch]$Apply
)

New-Item -ItemType Directory -Path (Split-Path $LogFile) -Force | Out-Null

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp $Message" | Tee-Object -FilePath $LogFile -Append
}

if (-not (Test-Path $BackupPath)) {
    Write-Log "ERROR: backup path not found: $BackupPath"
    exit 1
}

Write-Log "Starting backup verification. Apply=$Apply Path=$BackupPath MaxAgeHours=$MaxAgeHours"

if (-not $Apply) {
    Write-Log "DRY-RUN: would verify newest backup age and checksums."
    exit 0
}

$latestFile = Get-ChildItem -Path $BackupPath -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $latestFile) {
    Write-Log "ERROR: No backup files found in $BackupPath"
    exit 1
}

$ageHours = [int]((Get-Date) - $latestFile.LastWriteTime).TotalHours
if ($ageHours -gt $MaxAgeHours) {
    Write-Log "ALERT: Latest backup $($latestFile.FullName) is ${ageHours}h old"
} else {
    Write-Log "OK: Latest backup $($latestFile.FullName) is ${ageHours}h old"
}

$checksumPath = Join-Path $BackupPath "checksums.sha256"
if (Test-Path $checksumPath) {
    Write-Log "Verifying checksums"
    bash -lc "cd '$BackupPath' && sha256sum -c checksums.sha256"
} else {
    Write-Log "WARNING: No checksum manifest found (checksums.sha256)"
}

Write-Log "Backup verification complete."
