<#
.SYNOPSIS
    Copies files that exist in the source folder but are missing from the destination.
.EXAMPLE
    .\Sync-Nest.ps1 -WhatIf      # preview what would be copied
    .\Sync-Nest.ps1              # do the copy
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$Source      = 'C:\video\nest',
    [string]$Destination = 'E:\video\nest'
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $Source))      { throw "Source not found: $Source" }
if (-not (Test-Path -LiteralPath $Destination)) {
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
}

$srcRoot = (Resolve-Path -LiteralPath $Source).ProviderPath.TrimEnd('\')
$files   = Get-ChildItem -LiteralPath $srcRoot -File -Recurse -Force

$copied = 0; $skipped = 0; $failed = 0
$i = 0

foreach ($file in $files) {
    $i++
    $relative = $file.FullName.Substring($srcRoot.Length).TrimStart('\')
    $target   = Join-Path $Destination $relative

    Write-Progress -Activity "Comparing $Source -> $Destination" `
                   -Status $relative -PercentComplete (($i / $files.Count) * 100)

    if (Test-Path -LiteralPath $target) { $skipped++; continue }

    if ($PSCmdlet.ShouldProcess($target, "Copy from $($file.FullName)")) {
        try {
            $targetDir = Split-Path -Path $target -Parent
            if (-not (Test-Path -LiteralPath $targetDir)) {
                New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
            }
            Copy-Item -LiteralPath $file.FullName -Destination $target
            Write-Host "Copied: $relative" -ForegroundColor Green
            $copied++
        }
        catch {
            Write-Warning "Failed: $relative - $($_.Exception.Message)"
            $failed++
        }
    }
}

Write-Progress -Activity "Comparing" -Completed
Write-Host ""
Write-Host "Done. Copied: $copied   Already present: $skipped   Failed: $failed"