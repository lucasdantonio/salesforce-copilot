<#
.SYNOPSIS
Fails when a production org shows drift against the repository.

.DESCRIPTION
Runs the retrieve and compare flow, prints a summary, and returns a non-zero
exit code when the target org looks production-like and drift exists.

.EXAMPLE
.\fail-if-prod-drift.ps1 -TargetOrg my-prod
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$TargetOrg,

    [Parameter()]
    [string]$RetrievedPath = '.sf\drift\retrieved',

    [Parameter()]
    [string]$CompareResultPath = '.sf\drift\drift-report.json',

    [Parameter()]
    [string]$ProductionAliasPattern = '(?i)(prod|production)',

    [Parameter()]
    [switch]$EnforceForAllOrgs
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$isProductionLike = $EnforceForAllOrgs.IsPresent -or $TargetOrg -match $ProductionAliasPattern

& (Join-Path -Path $PSScriptRoot -ChildPath 'retrieve-org-metadata.ps1') -TargetOrg $TargetOrg -OutputPath $RetrievedPath | Out-Null
& (Join-Path -Path $PSScriptRoot -ChildPath 'compare-with-repo.ps1') -RetrievedPath $RetrievedPath -OutputPath $CompareResultPath | Out-Null
$reportJson = & (Join-Path -Path $PSScriptRoot -ChildPath 'report-drift.ps1') -RetrievedPath $RetrievedPath -CompareResultPath $CompareResultPath -AsJson
$findings = if ([string]::IsNullOrWhiteSpace($reportJson)) { @() } else { @((ConvertFrom-Json -InputObject $reportJson)) }

Write-Output ("Target org          : {0}" -f $TargetOrg)
Write-Output ("Production-like org : {0}" -f $isProductionLike)
Write-Output ("Drift findings      : {0}" -f $findings.Count)

if ($findings.Count -gt 0 -and $isProductionLike) {
    Write-Error 'Production-like org drift detected.'
    exit 1
}

if ($findings.Count -gt 0) {
    Write-Warning 'Drift detected, but the current org is not treated as production by this script.'
}
