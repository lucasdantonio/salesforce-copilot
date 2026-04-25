<#
.SYNOPSIS
Lists git-changed files for a Salesforce delta workflow.

.DESCRIPTION
Prints file-level changes between two refs and can emit JSON for automation.

.EXAMPLE
.\git-changed-files.ps1 -BaseRef origin/main -HeadRef HEAD

.EXAMPLE
.\git-changed-files.ps1 -BaseRef HEAD~1 -HeadRef HEAD -AsJson
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string]$BaseRef = 'HEAD~1',

    [Parameter()]
    [string]$HeadRef = 'HEAD',

    [Parameter()]
    [switch]$IncludeUntracked,

    [Parameter()]
    [switch]$AsJson
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\scripts\salesforce\SalesforceCopilotUtils.psm1') -Force

$entries = @(Get-GitDiffEntry -BaseRef $BaseRef -HeadRef $HeadRef -IncludeUntracked:$IncludeUntracked.IsPresent)

if ($AsJson.IsPresent) {
    $entries | ConvertTo-Json -Depth 5
    return
}

Write-Output ("Found {0} changed file(s) between {1} and {2}." -f $entries.Count, $BaseRef, $HeadRef)
$entries | Sort-Object Status, Path
