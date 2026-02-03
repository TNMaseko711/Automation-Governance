[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$InputCsv,
    [string]$DefaultGroups = "",
    [string]$Shell = "/bin/bash",
    [string]$LogFile = ("./logs/user_onboarding_{0:yyyyMMdd}.log" -f (Get-Date)),
    [switch]$Apply
)

New-Item -ItemType Directory -Path (Split-Path $LogFile) -Force | Out-Null

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp $Message" | Tee-Object -FilePath $LogFile -Append
}

if (-not (Test-Path $InputCsv)) {
    Write-Log "ERROR: Input CSV not found: $InputCsv"
    exit 1
}

Write-Log "Starting user onboarding. Apply=$Apply Input=$InputCsv"

Import-Csv $InputCsv | ForEach-Object {
    $username = $_.username
    $fullName = $_.full_name
    $primaryGroup = $_.primary_group
    $extraGroups = $_.extra_groups

    if (-not $username) { return }

    try {
        $null = Get-LocalUser -Name $username -ErrorAction Stop
        Write-Log "User exists: $username. Skipping create."
        return
    } catch {
        # user does not exist
    }

    $finalGroups = $extraGroups
    if ($DefaultGroups) {
        if ($finalGroups) {
            $finalGroups = "$finalGroups,$DefaultGroups"
        } else {
            $finalGroups = $DefaultGroups
        }
    }

    $command = "useradd -m -s $Shell -c `"$fullName`""
    if ($primaryGroup) { $command += " -g $primaryGroup" }
    if ($finalGroups) { $command += " -G $finalGroups" }
    $command += " $username"

    if ($Apply) {
        Write-Log "Creating user: $username"
        bash -lc $command
    } else {
        Write-Log "DRY-RUN: $command"
    }
}

Write-Log "Completed user onboarding."
