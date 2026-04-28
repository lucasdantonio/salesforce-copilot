<#
.SYNOPSIS
Prints a Salesforce-aware summary of changed metadata.

.DESCRIPTION
Summarizes changed files and their mapped Salesforce metadata members between
two refs. Also reports unmapped files under force-app for manual review.

.EXAMPLE
.\print-delta-summary.ps1 -BaseRef origin/main -HeadRef HEAD
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string]$BaseRef = 'HEAD~1',

    [Parameter()]
    [string]$HeadRef = 'HEAD',

    [Parameter()]
    [switch]$IncludeUntracked
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\scripts\salesforce\SalesforceCopilotUtils.psm1') -Force

$metadataRoot = Get-MetadataRootRelativePath
$entries = @(Get-GitDiffEntry -BaseRef $BaseRef -HeadRef $HeadRef -IncludeUntracked:$IncludeUntracked.IsPresent)
$metadata = @(Get-ChangedMetadataDescriptor -BaseRef $BaseRef -HeadRef $HeadRef -IncludeUntracked:$IncludeUntracked.IsPresent)
$unmapped = @(foreach ($entry in $entries) {
    $relativePath = Get-NormalizedRelativePath -Path $entry.Path

    if ($relativePath -like "$metadataRoot/*" -and $null -eq (Get-SalesforceMetadataDescriptor -Path $entry.Path)) {
        [PSCustomObject]@{
            Status = $entry.Status
            Path   = $relativePath
        }
    }
})

Write-Output ("Delta summary for {0} -> {1}" -f $BaseRef, $HeadRef)
Write-Output ("Files changed: {0}" -f $entries.Count)
Write-Output ("Mapped metadata members: {0}" -f (@($metadata | Sort-Object Type, Member -Unique).Count))

Write-Output ''
Write-Output 'Changes by git status:'
$entries | Group-Object -Property Status | Sort-Object Name | ForEach-Object {
    [PSCustomObject]@{
        Status = $_.Name
        Count  = $_.Count
    }
}

Write-Output ''
Write-Output 'Metadata by type:'
$metadata | Group-Object -Property Type | Sort-Object Name | ForEach-Object {
    [PSCustomObject]@{
        Type    = $_.Name
        Members = (@($_.Group | Sort-Object Member -Unique)).Count
    }
}

if ($unmapped.Count -gt 0) {
    Write-Output ''
    Write-Warning ("Found {0} unmapped file(s) under {1}. Review these before deploying." -f $unmapped.Count, $metadataRoot)
    $unmapped | Sort-Object Path
}
