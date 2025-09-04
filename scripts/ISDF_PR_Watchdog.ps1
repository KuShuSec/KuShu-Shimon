# Ensures a Scheduled Task exists that triggers PushLaunch, "Schedule #3*" tasks, and IME compliance sync.
# Safe to re-run (idempotent). Scope this deployment to your "enhanced monitoring" devices.

#Requires -RunAsAdministrator
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

$taskPath = '\ISDF\'
$taskName = 'ComplianceSync'

# 1) Build the action: 64-bit PowerShell, hidden window, tiny jitter, then run the three actions
$psExe = "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe"
$inline = @'
$ErrorActionPreference = "SilentlyContinue"
Start-Sleep -Seconds (Get-Random -Minimum 5 -Maximum 45)  # small jitter

# 1) Run all copies of PushLaunch
Get-ScheduledTask -TaskName "PushLaunch" -ErrorAction SilentlyContinue | ForEach-Object {
  $_ | Start-ScheduledTask
}

# 2) Run all copies whose name starts with "Schedule #3"
Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
  $_.TaskName -like "Schedule #3*"
} | ForEach-Object {
  $_ | Start-ScheduledTask
}

# 3) Trigger IME compliance sync
try { Start-Process 'intunemanagementextension://synccompliance' -WindowStyle Hidden | Out-Null } catch {}

exit 0
'@

# Use -EncodedCommand to avoid quoting/length issues (UTF-16LE)
$encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($inline))
$arg = '-NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -EncodedCommand ' + $encoded

$action = New-ScheduledTaskAction -Execute $psExe -Argument $arg

# 2) Triggers: at startup, at logon, and every 15 minutes (Indefinitely when RepetitionDuration is omitted)
$trigStartup = New-ScheduledTaskTrigger -AtStartup
$trigLogon   = New-ScheduledTaskTrigger -AtLogOn
$trigRepeat  = New-ScheduledTaskTrigger -Once -At (Get-Date).Date `
               -RepetitionInterval (New-TimeSpan -Minutes 15)

# 3) Run as SYSTEM, highest privileges
$principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -RunLevel Highest -LogonType ServiceAccount

# 4) Settings: allow on battery, wake not required, stop if running > 5 min, ignore overlapping runs
$settings = New-ScheduledTaskSettingsSet `
  -AllowStartIfOnBatteries `
  -DontStopIfGoingOnBatteries `
  -StartWhenAvailable `
  -ExecutionTimeLimit (New-TimeSpan -Minutes 5) `
  -Compatibility Win8 `
  -MultipleInstances IgnoreNew

# 5) Register (create or update in place)
$task = New-ScheduledTask -Action $action -Trigger @($trigStartup,$trigLogon,$trigRepeat) `
        -Principal $principal -Settings $settings

try {
  if (-not (Get-ScheduledTask -TaskPath $taskPath -TaskName $taskName -ErrorAction SilentlyContinue)) {
    Register-ScheduledTask -TaskPath $taskPath -TaskName $taskName -InputObject $task | Out-Null
  } else {
    Register-ScheduledTask -TaskPath $taskPath -TaskName $taskName -InputObject $task -Force | Out-Null
  }
  Write-Information "ISDF: ComplianceSync task is present and up to date."
} catch {
  Register-ScheduledTask -TaskPath $taskPath -TaskName $taskName -InputObject $task | Out-Null
  Write-Information "ISDF: ComplianceSync task created."
}
