# ISDF_Detect.ps1  RC1 -- single self-healing detection (PS 5.1 safe)
# Mode-aware detection for ISDF. Emits ISDF_* JSON, then:
# exit 0 only if ALL required booleans are true, else exit 1.

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ================================================================================================
# 0) 64-bit bootstrap
# ================================================================================================
function Restart-Into64Bit {
    try {
        if ([Environment]::Is64BitOperatingSystem -and -not [Environment]::Is64BitProcess) {
            $sysNative = "$env:WINDIR\SysNative\WindowsPowerShell\v1.0\powershell.exe"
            if (Test-Path $sysNative) {
                $args = @('-NoLogo','-NoProfile','-ExecutionPolicy','Bypass','-File', $PSCommandPath)
                Start-Process -FilePath $sysNative -ArgumentList $args -WindowStyle Hidden
                exit 0
            }
        }
    } catch {}
}
Restart-Into64Bit

# ================================================================================================
# 1) Constants & simple registry helpers
# ================================================================================================
$RegBase = 'HKLM:\SOFTWARE\ISDF'
$NowUtc  = [DateTime]::UtcNow

function Ensure-RegKey { param([string]$Path) if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null } }
function Set-Reg {
    param(
        [string]$Name,
        [object]$Value,
        [Microsoft.Win32.RegistryValueKind]$Kind = [Microsoft.Win32.RegistryValueKind]::String
    )
    Ensure-RegKey $RegBase
    New-ItemProperty -Path $RegBase -Name $Name -Value $Value -PropertyType $Kind -Force | Out-Null
}
function Get-RegOrNull { param([string]$Name) try { (Get-ItemProperty -Path $RegBase -Name $Name -ErrorAction Stop).$Name } catch { $null } }

# ================================================================================================
# 2) System / IMDS / AAD helpers
# ================================================================================================
function Get-SystemInfo {
    $rk = 'HKLM:\SYSTEM\CurrentControlSet\Control\SystemInformation'
    try {
        $m = Get-ItemProperty -Path $rk -ErrorAction Stop
        [pscustomobject]@{
            SystemManufacturer = $m.SystemManufacturer
            SystemProductName  = $m.SystemProductName
        }
    } catch {
        [pscustomobject]@{ SystemManufacturer=''; SystemProductName='' }
    }
}

function Get-IMDSCompute {
    try {
        Invoke-RestMethod -Method GET -Uri 'http://169.254.169.254/metadata/instance/compute?api-version=2021-02-01' `
            -Headers @{ Metadata='true' } -TimeoutSec 2
    } catch { $null }
}

function Get-DsRegStatusText { try { (& "dsregcmd.exe" /status) | Out-String } catch { '' } }
function Parse-GuidFromText { param([string]$Text,[string[]]$Labels)
    foreach ($label in $Labels) {
        $m = [regex]::Match($Text, "^\s*$label\s*:\s*([0-9a-fA-F-]{36})\s*$", 'Multiline')
        if ($m.Success) { return $m.Groups[1].Value }
    }
    $null
}
function Get-AADIds {
    $txt = Get-DsRegStatusText
    $tenantId = Parse-GuidFromText -Text $txt -Labels @('TenantId','AzureAdTenantId','Tenant Id')
    $deviceId = Parse-GuidFromText -Text $txt -Labels @('DeviceId','AzureAdDeviceId','Device Id')
    [pscustomobject]@{ TenantId=$tenantId; DeviceId=$deviceId }
}

# ================================================================================================
# 3) Tag & origin helpers
# ================================================================================================
function Parse-Tags {
    param($compute)
    $map = @{}

    if ($compute -and ($compute.tags -is [string]) -and $compute.tags.Length -gt 0) {
        foreach ($pair in ($compute.tags -split ';')) {
            if ($pair -match '=') {
                $k,$v = $pair -split '=',2
                if ($k) { $map[$k.Trim().ToLower()] = $v.Trim() }
            }
        }
    }

    if ($compute -and $compute.tagsList) {
        foreach ($t in $compute.tagsList) {
            if ($t -is [string]) {
                $m = [regex]::Match($t, 'name\s*=\s*([^;]+);\s*value\s*=(.+)\}?$')
                if ($m.Success) { $map[$m.Groups[1].Value.Trim().ToLower()] = $m.Groups[2].Value.Trim() }
            } elseif ($t -and $t.name) {
                $map[[string]$t.name.ToLower()] = [string]$t.value
            }
        }
    }

    $map
}

function Get-OriginSourceArmText {
    param($compute)
    $vals = @()

    try {
        if ($compute -and $compute.tagsList) {
            foreach ($t in $compute.tagsList) {
                if ($t -and $t.name -and $t.value) {
                    if ([string]$t.name -like 'ms.inv.v0.backedby.origin.sourcearmid*') {
                        $vals += [string]$t.value
                    }
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

function Has-DTLHiddenTags {
    param($compute, $tagsMap)
    if ($tagsMap) {
        foreach ($k in $tagsMap.Keys) {
            if ($k -match '^hidden-devtestlabs-') { return $true }
        }
    }
    if ($compute -and $compute.tagsList) {
        foreach ($t in $compute.tagsList) {
            if ($t -and $t.name -and ([string]$t.name).ToLower() -match '^hidden-devtestlabs-') { return $true }
        }
    }
    $false
}

function Test-ZeroGuid([string]$g){ return [bool]($g -match '^(00000000-0000-0000-0000-000000000000)$') }

# ================================================================================================
# 4) Channel derivation & validation
# ================================================================================================
function Derive-Channel {
    param($compute, $tagsMap, $sys)

    if (-not $compute) { return 'ISDF:AzureVM' }

    $srcText = Get-OriginSourceArmText -compute $compute  # already lowercased
    if (-not [string]::IsNullOrEmpty($srcText)) {
        if ($srcText -match '/subscriptions/00000000-0000-0000-0000-000000000000') { return 'ISDF:W365' }
        if ($srcText -match '/providers/microsoft\.devcenter')                   { return 'ISDF:DevBox' }
        if ($srcText -match '/providers/microsoft\.desktopvirtualization')       { return 'ISDF:AVD' }
        if ($srcText -match '/providers/microsoft\.devtestlab')                  { return 'ISDF:DevTestLabs' }
    }

    $ridL  = ([string]$compute.resourceId).ToLower()
    if ($ridL -match 'microsoft\.desktopvirtualization/hostpools') { return 'ISDF:AVD' }
    if (Has-DTLHiddenTags -compute $compute -tagsMap $tagsMap)     { return 'ISDF:DevTestLabs' }

    $nameL = ([string]$compute.osProfile.computerName).ToLower()
    $isCloudPC = ($compute.isHostCompatibilityLayerVm -eq $true) -or ($nameL -like 'cpc_*')
    if ($isCloudPC) { return 'ISDF:W365' }

    'ISDF:AzureVM'
}

function Channel-Ok {
    param($channel, $compute, $tagsMap, $sys)
    $ridL  = ([string]$compute.resourceId).ToLower()
    $manOk = ($sys.SystemManufacturer -like 'Microsoft*')
    $prodOk = ($sys.SystemProductName -match '^(Virtual($| )|Virtual Machine|Cloud PC|Microsoft Dev Box)')

    switch ($channel) {
        'ISDF:W365'   { return $true }
        'ISDF:DevBox' { return $true }
        'ISDF:AVD'    { return (-not (Test-ZeroGuid ([string]$compute.subscriptionId))) -and ($ridL -match 'microsoft\.desktopvirtualization/hostpools') }
        'ISDF:DevTestLabs' {
            if (Test-ZeroGuid ([string]$compute.subscriptionId)) { return $false }
            if (Has-DTLHiddenTags -compute $compute -tagsMap $tagsMap) { return $true }
            return $false
        }
        default { return $false }
    }
}

# ================================================================================================
# 5) Crypto helpers
# ================================================================================================
function To-JsonMin { param([hashtable]$Ordered) ($Ordered | ConvertTo-Json -Depth 8 -Compress) }

function Get-Key16FromTuple { param([string]$Tuple)
    $bytes=[Text.Encoding]::UTF8.GetBytes($Tuple.ToLower())
    $sha=[Security.Cryptography.SHA256]::Create()
    $h=$sha.ComputeHash($bytes)
    $h[0..15]
}

function Protect-Plaintext { param([string]$Plain,[byte[]]$Key16)
    $sec=ConvertTo-SecureString -String $Plain -AsPlainText -Force
    ConvertFrom-SecureString -SecureString $sec -Key $Key16
}

function Unprotect-Cipher { param([string]$Cipher,[byte[]]$Key16)
    try {
        $sec=ConvertTo-SecureString -String $Cipher -Key $Key16
        $plain=[System.Net.NetworkCredential]::new('', $sec).Password
        ,$true,$plain
    } catch {
        ,$false,$null
    }
}

function To-Base64String { param([string]$s) [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($s)) }
function Sha256Hex {
    param([string]$s)
    $bytes=[Text.Encoding]::UTF8.GetBytes($s)
    $sha=[Security.Cryptography.SHA256]::Create()
    ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) -join ''
}

# ================================================================================================
# Certificate discovery
# ================================================================================================
function Get-IsdfDeviceCert {
    param(
        [string[]] $IssuerContains = @("CN=ISSUER","CN=ROOT")
    )
    $now = Get-Date
    $paths = @("Cert:\LocalMachine\My","Cert:\CurrentUser\My")
    foreach ($p in $paths) {
        $candidates = Get-ChildItem $p | Where-Object {
            $_.HasPrivateKey -and $_.NotBefore -le $now -and $_.NotAfter -ge $now
        } | Where-Object {
            ($_.Extensions | Where-Object { $_ -is [System.Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension] } | ForEach-Object { $_.EnhancedKeyUsages } | ForEach-Object { $_.Value }) -contains "1.3.6.1.5.5.7.3.2"
        } | Where-Object {
            $iss = $_.Issuer; $IssuerContains | Where-Object { $iss.IndexOf($_,[StringComparison]::OrdinalIgnoreCase) -ge 0 } | Select-Object -First 1
        } | Sort-Object NotBefore -Descending
        if ($candidates) { return $candidates[0] }
    }
    throw "No suitable device certificate found in LocalMachine/CurrentUser My."
}

# ================================================================================================
# 6) Gather inputs
# ================================================================================================
$compute = Get-IMDSCompute
$tagsMap = Parse-Tags $compute
$sys     = Get-SystemInfo
$aad     = Get-AADIds
$hostname = $env:COMPUTERNAME

# ================================================================================================
# 7) Channel + baseline signal
# ================================================================================================
$channel   = Derive-Channel -compute $compute -tagsMap $tagsMap -sys $sys
$channelOk = Channel-Ok     -channel $channel -compute $compute -tagsMap $tagsMap -sys $sys

$signalOrdered = [ordered]@{
    Version=2; TimestampUtc=$NowUtc.ToString('o')
    Hostname=$hostname; ProvisionedHostname=$compute.osProfile.computerName
    SystemManufacturer=$sys.SystemManufacturer; SystemProductName=$sys.SystemProductName
    AzEnvironment=$compute.azEnvironment; SubscriptionId=$compute.subscriptionId; ResourceGroup=$compute.resourceGroupName; VMId=$compute.vmId
    AadTenantId=$aad.TenantId; Channel=$channel; ResourceId=$compute.resourceId
}
$signalJson=To-JsonMin $signalOrdered

$tuple = "{0}|{1}|{2}|{3}|{4}|{5}" -f $compute.azEnvironment,$compute.subscriptionId,$compute.resourceGroupName,$compute.vmId,'',$aad.TenantId
$key16 = Get-Key16FromTuple $tuple

$signalHash      = Sha256Hex $signalJson
$originTupleHash = Sha256Hex $tuple
$signalCipherV2  = Protect-Plaintext -Plain $signalJson -Key16 $key16
$channelCipherV2 = Protect-Plaintext -Plain $channel    -Key16 $key16
$ea2Blob         = To-Base64String $signalCipherV2

Ensure-RegKey $RegBase
Set-Reg -Name 'Version'             -Value 2 -Kind DWord
Set-Reg -Name 'SignalB64'           -Value (To-Base64String $signalJson)
Set-Reg -Name 'SignalProtected_v2'  -Value $signalCipherV2
Set-Reg -Name 'ChannelProtected_v2' -Value $channelCipherV2
Set-Reg -Name 'BaselineVer'         -Value 2 -Kind DWord

$decOk,$decPlain    = Unprotect-Cipher -Cipher $signalCipherV2 -Key16 $key16
$liveEqualsDecrypted= ($decOk -and $decPlain -eq $signalJson)

# ================================================================================================
# 8) Settings
# ================================================================================================
$mode = Get-RegOrNull 'Mode'; if ([string]::IsNullOrWhiteSpace($mode)) { $mode='Local' }
$webhookUrl = Get-RegOrNull 'WebhookUrl'
$syncTtlHrsRaw = Get-RegOrNull 'SyncTTLHours'
if ([string]::IsNullOrWhiteSpace($syncTtlHrsRaw)) { $syncTtlHrs = 48 } else { $syncTtlHrs = [int]$syncTtlHrsRaw }
$lastCloudWriteUtc = Get-RegOrNull 'LastCloudWriteUtc'

# ================================================================================================
# 9) Compute ISDF_* booleans
# ================================================================================================
$ISDF=[ordered]@{}
$ISDF.ISDF_Mode                       = $mode
$ISDF.ISDF_Channel                    = $channel
$ISDF.ISDF_ChannelOk                  = [bool]$channelOk
$ISDF.ISDF_AzEnvOk                    = ($compute.azEnvironment -eq 'AzurePublicCloud')
$ISDF.ISDF_HostnameMatchesProvisioned = [string]::Equals($hostname, $compute.osProfile.computerName,'InvariantCultureIgnoreCase')
$ISDF.ISDF_SignalHash      = $signalHash
$ISDF.ISDF_OriginTupleHash = $originTupleHash
$manOk  = ([string]$sys.SystemManufacturer -match '^(?i)microsoft corporation$')
$expectedPrefixByChannel = @{ 'ISDF:W365'='^(?i)(Cloud PC|Virtual( Machine)?)'; 'ISDF:DevBox'='^(?i)(Microsoft Dev Box|Dev Box|Virtual( Machine)?)'; 'ISDF:AVD'='^(?i)Virtual( Machine)?'; 'ISDF:DevTestLabs'='^(?i)Virtual( Machine)?'; 'ISDF:AzureVM'='^(?i)Virtual( Machine)?' }
$pattern = $expectedPrefixByChannel[$channel]
$prodOk = ([string]$sys.SystemProductName -match $pattern)
$ISDF.ISDF_SystemManufacturerOk       = $manOk
$ISDF.ISDF_SystemProductNamePrefixOk  = $prodOk
# TenantId OK: prefer origin.tenantid; fallback 'tenantid' tag; else OK
$tenantTag = $null
if ($tagsMap -and ($tagsMap.Keys -contains 'ms.inv.v0.backedby.origin.tenantid')) {
    $tenantTag = $tagsMap['ms.inv.v0.backedby.origin.tenantid']
} elseif ($tagsMap -and ($tagsMap.Keys -contains 'tenantid')) {
    $tenantTag = $tagsMap['tenantid']
}
$ISDF.ISDF_TenantIdOK = if ($tenantTag) { [string]::Equals($tenantTag,$aad.TenantId,'InvariantCultureIgnoreCase') } else { $true }
$ISDF.ISDF_EA2_Decrypts       = [bool]$decOk
$ISDF.ISDF_LiveEqualsDecrypted= [bool]$liveEqualsDecrypted
$ISDF.ISDF_BaselineVer        = 2
$ISDF.ISDF_WebhookConfigured  = $false
$ISDF.ISDF_WebhookLastOk      = $false
$ISDF.ISDF_EA1_Matches        = $false
$ISDF.ISDF_EA2_Matches        = $false
$ISDF.ISDF_LastSyncFresh      = $false

# ================================================================================================
# 10) Optional Cloud Sync
# ================================================================================================
if ($mode -eq 'Cloud' -and $webhookUrl) {
    $ISDF.ISDF_WebhookConfigured = $true

    $payload = @{
        device = @{
            aadDeviceId = $aad.DeviceId
            hostname    = $env:COMPUTERNAME
            aadTenantId = $aad.TenantId
        }
        isdf = @{
            channel         = $channel
            ea2             = $ea2Blob
            signalHash      = $signalHash
            originTupleHash = $originTupleHash
            baselineVer     = $ISDF.ISDF_baselineVer
            timestampUtc    = (Get-Date).ToUniversalTime().ToString('o')
        }
    } | ConvertTo-Json -Depth 5

    try {
        $cert = Get-IsdfDeviceCert
        $resp = Invoke-RestMethod -Method POST -Uri $webhookUrl -Certificate $cert `
            -Body $payload -ContentType 'application/json' -TimeoutSec 30

        if ($resp -and $resp.syncResult -eq 'Success' -and $resp.echo.aadDeviceId -eq $aad.DeviceId) {
            $ISDF.ISDF_WebhookLastOk = $true
            }

        if ($resp.echo.originTupleHash -eq $originTupleHash) { 
            $ISDF.ISDF_EA1_Matches = $true
           }

        if ($resp.echo.signalHash      -eq $signalHash)      {
            $ISDF.ISDF_EA2_Matches = $true 
           }

        if ([datetime]$resp.processedAtUtc) {
            $utc = [datetime]$resp.processedAtUtc
            Set-Reg -Name 'LastCloudWriteUtc' -Value ($utc.ToUniversalTime().ToString('o'))
            $ISDF.ISDF_LastSyncFresh = ($utc -gt ([DateTime]::UtcNow).AddHours(-$syncTtlHrs))
        }
    }
    catch {
    }
}

# When NOT in Cloud mode, harmonize
if ($mode -ne 'Cloud') {
    $ISDF.ISDF_WebhookConfigured = $true
    $ISDF.ISDF_WebhookLastOk     = $true
    $ISDF.ISDF_EA1_Matches       = $true
    $ISDF.ISDF_EA2_Matches       = $true
    $ISDF.ISDF_LastSyncFresh     = $true
}

# ================================================================================================
# 11) Output + exit policy
# ================================================================================================
$payloadJson = ($ISDF | ConvertTo-Json -Compress)
$payloadJson

function Get-RequiredSettingNames([string]$m){
    $base = @(
        'ISDF_ChannelOk',
        'ISDF_TenantIdOK',
        'ISDF_AzEnvOk',
        'ISDF_HostnameMatchesProvisioned',
        'ISDF_SystemManufacturerOk',
        'ISDF_SystemProductNamePrefixOk',
        'ISDF_EA2_Decrypts',
        'ISDF_LiveEqualsDecrypted'
    )
    if ($m -eq 'Cloud') {
        $base + @('ISDF_WebhookConfigured','ISDF_WebhookLastOk','ISDF_EA1_Matches','ISDF_EA2_Matches','ISDF_LastSyncFresh')
    } else {
        $base
    }
}
$required = Get-RequiredSettingNames $mode

$allTrue = $true
foreach ($n in $required) {
    if (-not ($ISDF.Keys -contains "$n" -and $ISDF[$n] -eq $true)) { $allTrue = $false; break }
}

if ($allTrue) { exit 0 } else { exit 1 } 
