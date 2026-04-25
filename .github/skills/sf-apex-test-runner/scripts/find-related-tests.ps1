<#
.SYNOPSIS
Finds Apex test classes related to changed files.

.DESCRIPTION
Uses local class inventory, naming conventions, and in-file references to find
candidate Apex tests related to the provided git diff or explicit paths.

.EXAMPLE
.\find-related-tests.ps1 -BaseRef origin/main -HeadRef HEAD
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string]$BaseRef = 'HEAD~1',

    [Parameter()]
    [string]$HeadRef = 'HEAD',

    [Parameter()]
    [string[]]$ChangedPath,

    [Parameter()]
    [switch]$AsJson
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\scripts\salesforce\SalesforceCopilotUtils.psm1') -Force
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\scripts\salesforce\ApexTestCopilotUtils.psm1') -Force

$effectiveChangedPaths = @($ChangedPath | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

if ($effectiveChangedPaths.Count -eq 0) {
    $effectiveChangedPaths = @(Get-GitDiffEntry -BaseRef $BaseRef -HeadRef $HeadRef | ForEach-Object { $_.Path })
}

$tests = @(Find-RelatedApexTest -ChangedPath $effectiveChangedPaths)

if ($AsJson.IsPresent) {
    $tests | ConvertTo-Json -Depth 3
    return
}

Write-Output ("Found {0} related test class(es)." -f $tests.Count)
$tests
