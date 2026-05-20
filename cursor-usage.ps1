<#!
  Cursor usage (Windows) — stejný zdroj dat jako cursor-usage-menubar:
  GET https://cursor.com/api/usage-summary + cookie WorkosCursorSessionToken.

  Token (v tomto pořadí):
  1) parametr -SessionToken
  2) prostředí CURSOR_SESSION_TOKEN
  3) soubor %USERPROFILE%\.cursor-usage\config.json → { "session_token": "..." }

  Příklady:
    .\cursor-usage.ps1
    .\cursor-usage.ps1 -Watch -IntervalSeconds 300
    $env:CURSOR_SESSION_TOKEN = '...'; .\cursor-usage.ps1 -Watch

  -NotifyAtPercent 0 vypne upozornění na „blíží se limit“ (kromě 100 % dle reportu).
#>
[CmdletBinding()]
param(
    [string]$SessionToken,
    [string]$ConfigPath = (Join-Path $env:USERPROFILE ".cursor-usage\config.json"),
    [switch]$Watch,
    [ValidateRange(30, 86400)]
    [int]$IntervalSeconds = 300,
    [ValidateRange(0, 100)]
    [int]$NotifyAtPercent = 90
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-SessionToken {
    param([string]$Explicit, [string]$ConfigFile)
    if ($Explicit) { return $Explicit }
    $fromEnv = [Environment]::GetEnvironmentVariable("CURSOR_SESSION_TOKEN", "Process")
    if (-not [string]::IsNullOrWhiteSpace($fromEnv)) { return $fromEnv.Trim() }
    if (Test-Path -LiteralPath $ConfigFile) {
        try {
            $cfg = Get-Content -LiteralPath $ConfigFile -Raw -Encoding UTF8 | ConvertFrom-Json
            $t = $cfg.session_token
            if ($t) { return [string]$t }
        } catch { }
    }
    return $null
}

function Get-Num {
    param($Value, [double]$Default = 0)
    if ($null -eq $Value) { return $Default }
    return [double]$Value
}

function Get-CursorUsageSummary {
    param([string]$Token)
    $uri = "https://cursor.com/api/usage-summary"
    $headers = @{
        Cookie       = "WorkosCursorSessionToken=$Token"
        "User-Agent" = "cursor-usage-windows/1.0"
    }
    $prev = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'
    try {
        return Invoke-RestMethod -Uri $uri -Headers $headers -Method Get -TimeoutSec 20
    } finally {
        $ProgressPreference = $prev
    }
}

function Get-BillingDaysRemaining {
    param([string]$EndIso)
    if ([string]::IsNullOrWhiteSpace($EndIso)) { return -1 }
    try {
        $end = [datetimeoffset]::Parse($EndIso)
        $now = [datetimeoffset]::UtcNow
        $d = ($end - $now).TotalDays
        if ($d -lt 0) { return 0 }
        return [int][math]::Floor($d)
    } catch {
        return -1
    }
}

function Format-PercentBar {
    param(
        [double]$Percent,
        [int]$Width = 12
    )
    $p = [math]::Max(0, [math]::Min(100, $Percent))
    $filled = [int][math]::Round($p / 100.0 * $Width)
    $bar = ('#' * $filled) + ('.' * ($Width - $filled))
    return $bar
}

function Show-UsageBlock {
    param(
        [object]$Data,
        [datetime]$FetchedAt,
        [bool]$IsWatch
    )
    if ($null -eq $Data -or $null -eq $Data.individualUsage) {
        Write-Warning "Neočekávaná odpověď API (chybí individualUsage)."
        return
    }
    $ind = $Data.individualUsage
    $plan = $ind.plan
    $onDemand = $ind.onDemand
    if ($null -eq $plan) { $plan = [pscustomobject]@{} }
    if ($null -eq $onDemand) { $onDemand = [pscustomobject]@{} }

    $autoPct      = Get-Num $plan.autoPercentUsed
    $apiPct       = Get-Num $plan.apiPercentUsed
    $totalPct     = Get-Num $plan.totalPercentUsed
    $odUsed       = Get-Num $onDemand.used
    $odLimit      = $onDemand.limit

    $days = Get-BillingDaysRemaining -EndIso ([string]$Data.billingCycleEnd)
    $membership = ([string]$Data.membershipType).Replace("_", " ")
    if ([string]::IsNullOrWhiteSpace($membership)) { $membership = "?" }

    $used = $plan.used
    $limit = $plan.limit

    if ($IsWatch) { Clear-Host }
    Write-Host ("Cursor usage - {0:yyyy-MM-dd HH:mm:ss} (local)" -f $FetchedAt) -ForegroundColor Cyan
    Write-Host ("Membership: {0}  |  Billing cycle end: {1}  |  Days left: {2}" -f $membership, $Data.billingCycleEnd, $(if ($days -ge 0) { $days } else { "?" }))
    Write-Host ""

    $autoBar = Format-PercentBar -Percent $autoPct
    $apiBar = Format-PercentBar -Percent $apiPct
    $totalBar = Format-PercentBar -Percent $totalPct
    Write-Host ("Total (Included)  : {0} {1,6:N1} %" -f $totalBar, $totalPct) -ForegroundColor Cyan
    Write-Host ("Auto + Composer : {0} {1,6:N1} %" -f $autoBar, $autoPct) -ForegroundColor Green
    Write-Host ("API (Named)     : {0} {1,6:N1} %" -f $apiBar, $apiPct) -ForegroundColor Yellow
    Write-Host ""

    $odLine = ("On demand: {0:N2}" -f $odUsed)
    if ($null -ne $odLimit -and [double]$odLimit -gt 0) {
        $odLine += (" / {0:N2}" -f [double]$odLimit)
    }
    Write-Host $odLine

    if ($null -ne $limit -and [double]$limit -gt 0 -and $null -ne $used) {
        Write-Host ("Plan total (API fields): {0:N0} / {1:N0}" -f [double]$used, [double]$limit)
    }

    Write-Host ""
    Write-Host "Pozn.: Cursor API typicky neslibuje den/teden jako Claude Code - mesicni cyklus a 2 pooly (Auto + API)."
    if ($IsWatch) { Write-Host "Ctrl+C ukončí sledování." }
}

function Show-WindowsBalloon {
    param([string]$Title, [string]$Message)
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        Add-Type -AssemblyName System.Drawing -ErrorAction Stop
        $ni = New-Object System.Windows.Forms.NotifyIcon
        $ni.Visible = $true
        $ni.Icon = [System.Drawing.SystemIcons]::Information
        $ni.BalloonTipTitle = $Title
        $ni.BalloonTipText = $Message
        $ni.ShowBalloonTip(8000)
        Start-Sleep -Milliseconds 500
        $ni.Visible = $false
        $ni.Dispose()
    } catch {
        [Console]::Beep(880, 200)
        Write-Warning "$Title - $Message"
    }
}

function Get-HttpStatusFromError {
    param($ErrorRecord)
    try {
        $r = $ErrorRecord.Exception.Response
        if ($null -eq $r) { return $null }
        return [int]$r.StatusCode
    } catch {
        return $null
    }
}

$token = Get-SessionToken -Explicit $SessionToken -ConfigFile $ConfigPath
if ([string]::IsNullOrWhiteSpace($token)) {
    Write-Error (
        "Missing WorkosCursorSessionToken. Copy cookie WorkosCursorSessionToken from cursor.com (DevTools / Application / Cookies). " +
        "Then set environment variable CURSOR_SESSION_TOKEN for this session, or create JSON at " + $ConfigPath + " with property session_token. " +
        "Do not commit the token. See comment block at top of this script."
    )
}

$notifiedOverLimit = $false
$prevAuto = [double]::NaN
$prevApi = [double]::NaN

$loop = $true
while ($loop) {
    try {
        $data = Get-CursorUsageSummary -Token $token
        $fetched = [datetime]::Now
        Show-UsageBlock -Data $data -FetchedAt $fetched -IsWatch:$Watch

        $plan = $data.individualUsage.plan
        if ($null -eq $plan) { $plan = [pscustomobject]@{} }
        $autoPct = Get-Num $plan.autoPercentUsed
        $apiPct = Get-Num $plan.apiPercentUsed

        if ($autoPct -lt 100 -and $apiPct -lt 100) {
            $notifiedOverLimit = $false
        }
        if (($autoPct -ge 100 -or $apiPct -ge 100) -and -not $notifiedOverLimit) {
            $notifiedOverLimit = $true
            $which = if ($autoPct -ge 100) { "Auto + Composer" } else { "API (Named)" }
            Show-WindowsBalloon -Title "Cursor usage" -Message ("Reported limit reached (100 pct+) - {0}" -f $which)
        }

        if ($NotifyAtPercent -gt 0) {
            if (-not [double]::IsNaN($prevAuto) -and $prevAuto -lt $NotifyAtPercent -and $autoPct -ge $NotifyAtPercent -and $autoPct -lt 100) {
                Show-WindowsBalloon -Title "Cursor usage" -Message ("Auto + Composer reached {0} pct (now {1:N0} pct)." -f $NotifyAtPercent, $autoPct)
            }
            if (-not [double]::IsNaN($prevApi) -and $prevApi -lt $NotifyAtPercent -and $apiPct -ge $NotifyAtPercent -and $apiPct -lt 100) {
                Show-WindowsBalloon -Title "Cursor usage" -Message ("API (Named) reached {0} pct (now {1:N0} pct)." -f $NotifyAtPercent, $apiPct)
            }
        }
        $prevAuto = $autoPct
        $prevApi = $apiPct

        if (-not $Watch) { $loop = $false }
        else { Start-Sleep -Seconds $IntervalSeconds }
    } catch {
        $code = Get-HttpStatusFromError -ErrorRecord $_
        if ($null -ne $code -and ($code -eq 401 -or $code -eq 403)) {
            Write-Error ("HTTP {0} - token invalid or expired. Refresh CURSOR_SESSION_TOKEN or config.json." -f $code)
        }
        if (-not $Watch) { throw }
        Write-Warning $_.Exception.Message
        Start-Sleep -Seconds $IntervalSeconds
    }
}
