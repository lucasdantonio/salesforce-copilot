<#
.SYNOPSIS
Flags noisy profile diffs for manual review.

.DESCRIPTION
Checks changed profile metadata and warns when the diff is large or when only
profiles changed, which often indicates deploy noise instead of intentional access work.

.EXAMPLE
.\check-profile-noise.ps1 -BaseRef origin/main -HeadRef HEAD
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string]$BaseRef = 'HEAD~1',

    [Parameter()]
    [string]$HeadRef = 'HEAD',

    [Parameter()]
    [int]$LineThreshold = 50
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\scripts\salesforce\SalesforceCopilotUtils.psm1') -Force

$entries = @(Get-GitDiffEntry -BaseRef $BaseRef -HeadRef $HeadRef)
$profilePaths = @($entries.Path | Where-Object { $_ -match '^force-app/main/default/profiles/.+\.profile-meta\.xml$' } | Sort-Object -Unique)

if ($profilePaths.Count -eq 0) {
    Write-Output 'No changed profiles were found.'
    return
}

$nonProfileMetadata = @(
    $entries.Path |
        Where-Object { $_ -match '^force-app/main/default/' -and $_ -notmatch '^force-app/main/default/profiles/' }
)

$findings = @(foreach ($profilePath in $profilePaths) {
    $diffLines = & git --no-pager diff --unified=0 $BaseRef $HeadRef -- $profilePath
    $lineCount = @(
        $diffLines |
            Where-Object {
                $_ -match '^[+-]' -and
                $_ -notmatch '^(---|\+\+\+)' -and
                -not [string]::IsNullOrWhiteSpace($_)
            }
    ).Count

    if ($lineCount -ge $LineThreshold -or $nonProfileMetadata.Count -eq 0) {
        [PSCustomObject]@{
            ProfilePath           = $profilePath
            ChangedLineCount      = $lineCount
            OnlyProfilesChanged   = [bool]($nonProfileMetadata.Count -eq 0)
        }
    }
})

if ($findings.Count -eq 0) {
    Write-Output 'No suspicious profile-only noise was detected.'
    return
}

Write-Warning ("Found {0} profile diff or diffs that deserve manual review." -f $findings.Count)
$findings
