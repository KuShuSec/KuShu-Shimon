# ISDF_PR_Detection.ps1
# Local decrypt + compare against canonical signal (no Offer/SKU).
# Exit 0 on match; Exit 1 on failure. PowerShell 5.1-safe.

[CmdletBinding()] param()
$ErrorActionPreference='Stop'
$RegBase='HKLM:\SOFTWARE\ISDF'

function Get-IMDSCompute { try { Invoke-RestMethod -Method GET -Uri 'http://169.254.169.254/metadata/instance/compute?api-version=2021-02-01' -Headers @{Metadata='true'} -TimeoutSec 2 } catch { $null } }
function Get-SystemInfo {
    $rk = 'HKLM:\SYSTEM\CurrentControlSet\Control\SystemInformation'
    try { $m = Get-ItemProperty -Path $rk -ErrorAction Stop; [pscustomobject]@{ SystemManufacturer=$m.SystemManufacturer; SystemProductName=$m.SystemProductName } }
    catch { [pscustomobject]@{ SystemManufacturer=''; SystemProductName='' } }
}
function Parse-Tags {
    param($compute)
    $map=@{}
    if($compute -and ($compute.tags -is [string])){ foreach($p in ($compute.tags -split ';')){ if($p -match '='){ $k,$v=$p -split '=',2; if($k){ $map[$k.Trim().ToLower()]=$v.Trim() }}}}
    if($compute -and $compute.tagsList){
        foreach($t in $compute.tagsList){
            if($t -is [string]){
                $m=[regex]::Match($t,'name\s*=\s*([^;]+);\s*value\s*=\s*(.+)\}?$')
                if($m.Success){ $map[$m.Groups[1].Value.Trim().ToLower()]=$m.Groups[2].Value.Trim() }
            } elseif($t -and $t.name){
                $map[[string]$t.name.ToLower()]=[string]$t.value
            }
        }
    }
    $map
}
function Get-OriginSourceArmText {
    param($compute)
    $vals=@()
    try {
        if ($compute -and $compute.tagsList) {
            foreach ($t in $compute.tagsList) {
                if ($t -and $t.name -and $t.value) {
                    if ([string]$t.name -like 'ms.inv.v0.backedby.origin.sourcearmid*') { $vals += [string]$t.value }
                }
            }
        }
    } catch {}
    try {
        if ($compute -and ($compute.tags -is [string]) -and $compute.tags.Length -gt 0) {
            foreach ($pair in ($compute.tags -split ';')) {
                if ($pair -match '=') {
                    $k,$v = $pair -split '=',2
                    if ($k -and ($k.Trim().ToLower() -like 'ms.inv.v0.backedby.origin.sourcearmid*')) { $vals += $v.Trim() }
                }
            }
        }
    } catch {}
    (($vals -join ';')).ToLower()
}
function Derive-Channel {
    param($compute, $tagsMap, $sys)
    if (-not $compute) { return 'ISDF:AzureVM' }
    $srcText = Get-OriginSourceArmText -compute $compute
    if (-not [string]::IsNullOrEmpty($srcText)) {
        if ($srcText -match '/subscriptions/00000000-0000-0000-0000-000000000000') { return 'ISDF:W365' }
        if ($srcText -match '/providers/microsoft\.devcenter')                   { return 'ISDF:DevBox' }
        if ($srcText -match '/providers/microsoft\.desktopvirtualization')       { return 'ISDF:AVD' }
        if ($srcText -match '/providers/microsoft\.devtestlab')                  { return 'ISDF:DevTestLabs' }
    }
    $ridL=([string]$compute.resourceId).ToLower()
    $nameL=([string]$compute.name).ToLower()
    if ($ridL -match 'microsoft\.desktopvirtualization/hostpools') { return 'ISDF:AVD' }
    if ($tagsMap){ foreach($k in $tagsMap.Keys){ if($k -match '^hidden-devtestlabs-'){ return 'ISDF:DevTestLabs' } } }
    if ( ($compute.isHostCompatibilityLayerVm -eq $true) -or ($nameL -like 'cpc_*') ) { return 'ISDF:W365' }
    'ISDF:AzureVM'
}
function ToJsonMin([hashtable]$h){ $h|ConvertTo-Json -Depth 8 -Compress }
function Key16([string]$t){ $b=[Text.Encoding]::UTF8.GetBytes($t.ToLower()); $sha=[Security.Cryptography.SHA256]::Create(); $h=$sha.ComputeHash($b); $h[0..15] }
function Unprotect([string]$c,[byte[]]$k){ try{ $s=ConvertTo-SecureString -String $c -Key $k; $p=[System.Net.NetworkCredential]::new('', $s).Password; ,$true,$p } catch { ,$false,$null } }

# Gather
$compute=Get-IMDSCompute
$sys=Get-SystemInfo
$tags=Parse-Tags $compute
$txt = (& "dsregcmd.exe" /status) | Out-String
$tenant = ([regex]::Match($txt,'^\s*(TenantId|AzureAdTenantId)\s*:\s*([0-9a-fA-F-]{36})\s*$', 'Multiline').Groups[2].Value)

# Hostname + provisioned name
$hostname=$env:COMPUTERNAME
$provComputer=$null
try {
    if ($compute -and ($compute | Get-Member -Name osProfile -ErrorAction SilentlyContinue)) {
        $osProf=$compute.osProfile
        if ($osProf -is [System.Collections.Hashtable]) { if($osProf.keys -contains 'computerName'){ $provComputer=[string]$osProf['computerName'] } }
        else { $provComputer=[string]$osProf.computerName }
    }
} catch {}
$provName = if ([string]::IsNullOrWhiteSpace($provComputer)) { [string]$compute.name } else { $provComputer }

# Canonical signal (no Offer/SKU)
$signal=[ordered]@{
  Version=2; Hostname=$hostname; ProvisionedHostname=$provName
  SystemManufacturer=$sys.SystemManufacturer; SystemProductName=$sys.SystemProductName
  AzEnvironment=$compute.azEnvironment; SubscriptionId=$compute.subscriptionId; ResourceGroup=$compute.resourceGroupName
  VMId=$compute.vmId; AadTenantId=$tenant; Channel=(Derive-Channel -compute $compute -tagsMap $tags -sys $sys); ResourceId=$compute.resourceId
}
$signalJson=ToJsonMin $signal

# Stable per-VM key
$tuple="{0}|{1}|{2}|{3}|{4}|{5}" -f $compute.azEnvironment,$compute.subscriptionId,$compute.resourceGroupName,$compute.vmId,'', $tenant
$key16=Key16 $tuple

# Compare against baseline
try { $cipher=(Get-ItemProperty -Path $RegBase -Name 'SignalProtected_v2' -ErrorAction Stop).'SignalProtected_v2' } catch { $cipher=$null }
if(-not $cipher){ Write-Host "SignalProtected_v2 missing"; exit 1 }

$ok,$plain=Unprotect $cipher $key16
if(-not $ok){ Write-Host "Decrypt failed"; exit 1 }
if($plain -ne $signalJson){ Write-Host "Decrypted baseline != live signal"; exit 1 }

Write-Host "Local decrypt+compare OK"; exit 0
