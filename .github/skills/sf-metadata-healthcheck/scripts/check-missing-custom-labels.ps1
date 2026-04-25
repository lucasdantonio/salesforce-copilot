<#
.SYNOPSIS
Flags files that may need Custom Labels instead of hardcoded UI strings.

.DESCRIPTION
Uses a conservative heuristic on changed source files to spot user-facing string
literals without nearby Custom Label usage.

.EXAMPLE
.\check-missing-custom-labels.ps1 -BaseRef origin/main -HeadRef HEAD
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string]$BaseRef = 'HEAD~1',

    [Parameter()]
    [string]$HeadRef = 'HEAD',

    [Parameter()]
    [string[]]$ChangedPath
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\scripts\salesforce\SalesforceCopilotUtils.psm1') -Force

$effectiveChangedPaths = @($ChangedPath | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

if ($effectiveChangedPaths.Count -eq 0) {
    $effectiveChangedPaths = @(Get-GitDiffEntry -BaseRef $BaseRef -HeadRef $HeadRef | ForEach-Object { $_.Path })
}

$targetFiles = @(
    $effectiveChangedPaths |
        Where-Object { $_ -match '^force-app/main/default/.+\.(cls|js|html|page|component)$' } |
        ForEach-Object { Join-Path -Path (Get-RepositoryRoot) -ChildPath $_ } |
        Where-Object { Test-Path -Path $_ }
)

$quotedStringPattern = "('([^'`r`n]{12,})'|""([^""`r`n]{12,})"")"
$labelPattern = 'System\.Label\.|@salesforce/label/|\$Label\.'

$findings = @(foreach ($file in $targetFiles) {
    $content = Get-Content -Path $file -Raw

    if ($content -match $labelPattern) {
        continue
    }

    $matches = [regex]::Matches($content, $quotedStringPattern)
    $humanStrings = @(
        $matches |
            ForEach-Object {
                $_.Value.Trim([char[]]@("'", '"'))
            } |
            Where-Object { $_ -match '\s' -and $_ -notmatch 'SELECT |FROM |WHERE |http|https|api|<|>' }
    )

    if ($humanStrings.Count -ge 3) {
        [PSCustomObject]@{
            Path           = Get-NormalizedRelativePath -Path $file
            LiteralCount   = $humanStrings.Count
            ExampleLiteral = $humanStrings[0]
        }
    }
})

if ($findings.Count -eq 0) {
    Write-Output 'No strong Custom Label candidates were detected.'
    return
}

Write-Warning ("Found {0} file(s) with likely user-facing literals and no label usage." -f $findings.Count)
$findings | Sort-Object Path
