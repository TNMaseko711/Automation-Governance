[CmdletBinding()]
param(
    [string]$Output = ("./reports/password_expiry_{0:yyyyMMdd}.csv" -f (Get-Date)),
    [int]$MinUid = 1000,
    [string]$LogFile = ("./logs/password_expiry_{0:yyyyMMdd}.log" -f (Get-Date)),
    [switch]$Apply
)

New-Item -ItemType Directory -Path (Split-Path $LogFile) -Force | Out-Null
New-Item -ItemType Directory -Path (Split-Path $Output) -Force | Out-Null

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp $Message" | Tee-Object -FilePath $LogFile -Append
}

Write-Log "Starting password expiry report. Apply=$Apply MinUid=$MinUid"

if (-not (Get-Command chage -ErrorAction SilentlyContinue)) {
    Write-Log "ERROR: chage command not found."
    exit 1
}

if ($Apply) {
    "username,last_change,expires" | Out-File -FilePath $Output -Encoding utf8
}

Get-Content /etc/passwd | ForEach-Object {
    $parts = $_ -split ':'
    $username = $parts[0]
    $uid = [int]$parts[2]
    if ($uid -lt $MinUid) { return }

    if ($Apply) {
        $chage = chage -l $username
        $lastChange = ($chage | Select-String "Last password change").ToString().Split(':')[1].Trim()
        $expires = ($chage | Select-String "Password expires").ToString().Split(':')[1].Trim()
        "$username,$lastChange,$expires" | Out-File -FilePath $Output -Append -Encoding utf8
    } else {
        Write-Log "DRY-RUN: would inspect $username and append to report"
    }
}

if ($Apply) {
    Write-Log "Report written to $Output"
} else {
    Write-Log "Dry-run complete. Use -Apply to write the report."
}
