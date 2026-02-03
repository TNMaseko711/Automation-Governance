[CmdletBinding()]
param(
    [int]$Threshold = 80,
    [string]$LogFile = ("./logs/disk_space_{0:yyyyMMdd}.log" -f (Get-Date)),
    [string]$AlertFile = ("./alerts/disk_space_alerts_{0:yyyyMMdd}.txt" -f (Get-Date)),
    [switch]$Apply
)

New-Item -ItemType Directory -Path (Split-Path $LogFile) -Force | Out-Null
New-Item -ItemType Directory -Path (Split-Path $AlertFile) -Force | Out-Null

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp $Message" | Tee-Object -FilePath $LogFile -Append
}

Write-Log "Starting disk space monitor. Apply=$Apply Threshold=$Threshold"

if ($Apply) {
    "" | Out-File -FilePath $AlertFile
}

(df -P | Select-Object -Skip 1) | ForEach-Object {
    $columns = $_ -split '\s+'
    $filesystem = $columns[0]
    $usePct = $columns[4].TrimEnd('%')
    $mountPoint = $columns[5]

    if ([int]$usePct -ge $Threshold) {
        $message = "ALERT: $filesystem at $mountPoint is ${usePct}% full"
        if ($Apply) {
            $message | Out-File -FilePath $AlertFile -Append
        } else {
            Write-Log "DRY-RUN: would write '$message'"
        }
    }
}

if ($Apply) {
    Write-Log "Alerts written to $AlertFile"
} else {
    Write-Log "Dry-run complete. Use -Apply to write alerts."
}
