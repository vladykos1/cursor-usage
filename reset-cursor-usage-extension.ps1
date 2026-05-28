<#!
  Removes ghost "Cursor plan usage" extension entries from Cursor's registry.
  Use when VSIX reinstall fails with:
    "Please restart VS Code before reinstalling Cursor plan usage (status bar)."

  Run ONLY with Cursor fully closed (File -> Exit, all windows).
  Run ONLY from the official repo clone — review the script before executing.

  Examples:
    .\reset-cursor-usage-extension.ps1 -WhatIf
    .\reset-cursor-usage-extension.ps1
    .\reset-cursor-usage-extension.ps1 -SkipCliUninstall
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [switch]$SkipCliUninstall
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ExtensionIds = @(
    'local.cursor-usage-status'
    'lukasvladyka.cursor-usage-status'
)

function Test-EditorRunning {
    $names = @('Cursor', 'Code')
    foreach ($name in $names) {
        if (Get-Process -Name $name -ErrorAction SilentlyContinue) {
            return $name
        }
    }
    return $null
}

function Invoke-CliUninstall {
    param([string[]]$Ids)
    $cli = Get-Command cursor -ErrorAction SilentlyContinue
    if (-not $cli) {
        Write-Verbose 'cursor CLI not found in PATH — skipping CLI uninstall.'
        return
    }
    foreach ($id in $Ids) {
        if ($PSCmdlet.ShouldProcess($id, 'cursor --uninstall-extension')) {
            Write-Host "Trying: cursor --uninstall-extension $id"
            & cursor --uninstall-extension $id 2>&1 | ForEach-Object { Write-Host $_ }
        }
    }
}

function Get-ExtensionsRoot {
    $cursorRoot = Join-Path $env:USERPROFILE '.cursor\extensions'
    if (Test-Path -LiteralPath $cursorRoot) {
        return $cursorRoot
    }
    throw "Cursor extensions folder not found: $cursorRoot"
}

function Remove-GhostExtensionFolders {
    param(
        [string]$ExtensionsRoot,
        [string[]]$Ids
    )
    foreach ($id in $Ids) {
        $matches = Get-ChildItem -LiteralPath $ExtensionsRoot -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like "$id-*" }
        foreach ($dir in $matches) {
            if ($PSCmdlet.ShouldProcess($dir.FullName, 'Remove directory')) {
                Remove-Item -LiteralPath $dir.FullName -Recurse -Force
                Write-Host "Removed folder: $($dir.Name)"
            }
        }
    }
}

function Remove-GhostRegistryEntries {
    param(
        [string]$ExtensionsRoot,
        [string[]]$Ids
    )
    $registryPath = Join-Path $ExtensionsRoot 'extensions.json'
    if (-not (Test-Path -LiteralPath $registryPath)) {
        Write-Host 'No extensions.json found — nothing to clean in registry.'
        return 0
    }

    $raw = Get-Content -LiteralPath $registryPath -Raw -Encoding UTF8
    $entries = $raw | ConvertFrom-Json
    if ($null -eq $entries) {
        throw 'extensions.json is empty or invalid.'
    }

    $before = @($entries).Count
    $remaining = @($entries | Where-Object {
        $id = $_.identifier.id
        $Ids -notcontains $id
    })
    $removed = $before - $remaining.Count

    if ($removed -eq 0) {
        Write-Host 'No ghost registry entries for cursor-usage-status found.'
        return 0
    }

    if ($PSCmdlet.ShouldProcess($registryPath, "Remove $removed ghost entries")) {
        $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $backupPath = "$registryPath.bak.$timestamp"
        Copy-Item -LiteralPath $registryPath -Destination $backupPath -Force
        Write-Host "Backup: $backupPath"

        $json = $remaining | ConvertTo-Json -Depth 20 -Compress:$false
        $tempPath = "$registryPath.tmp"
        [System.IO.File]::WriteAllText($tempPath, $json, [System.Text.UTF8Encoding]::new($false))
        Move-Item -LiteralPath $tempPath -Destination $registryPath -Force
        Write-Host "Removed $removed ghost entries from extensions.json."
    }

    return $removed
}

$running = Test-EditorRunning
if ($running) {
    if ($WhatIfPreference) {
        Write-Warning "$running is still running. WhatIf preview only - quit Cursor and run again without -WhatIf to apply."
    } else {
        throw "$running is still running. Fully quit Cursor (File - Exit) before running this script."
    }
}

if (-not $SkipCliUninstall) {
    Invoke-CliUninstall -Ids $ExtensionIds
}

$extensionsRoot = Get-ExtensionsRoot
Remove-GhostExtensionFolders -ExtensionsRoot $extensionsRoot -Ids $ExtensionIds
$removedCount = Remove-GhostRegistryEntries -ExtensionsRoot $extensionsRoot -Ids $ExtensionIds

Write-Host ''
Write-Host 'Next steps:'
Write-Host '  1. Open Cursor'
Write-Host '  2. Ctrl+Shift+P -> Extensions: Install from VSIX...'
Write-Host '  3. Select cursor-usage-status-*.vsix from GitHub Releases'
Write-Host '  4. Ctrl+Shift+P -> Developer: Reload Window'

if ($removedCount -eq 0 -and -not $WhatIfPreference) {
    Write-Host ''
    Write-Host 'Registry was already clean. If VSIX install still fails, try a full Cursor restart once more.'
}
