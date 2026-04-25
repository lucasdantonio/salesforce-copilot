<#
.SYNOPSIS
Detects the recommended Apex test mode for the current change.

.DESCRIPTION
Evaluates changed metadata and optional explicitly provided tests to recommend
one of the supported Apex test runner modes.

.EXAMPLE
.\detect-test-scope.ps1 -BaseRef origin/main -HeadRef HEAD
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('auto', 'all-local', 'specified', 'changed-related', 'none')]
    [string]$Mode = 'auto',

    [Parameter()]
    [string]$BaseRef = 'HEAD~1',

    [Parameter()]
    [string]$HeadRef = 'HEAD',

    [Parameter()]
    [string[]]$SpecifiedTest,

    [Parameter()]
    [switch]$AsJson
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\scripts\salesforce\ApexTestCopilotUtils.psm1') -Force

$plan = Get-ApexTestPlan -Mode $Mode -BaseRef $BaseRef -HeadRef $HeadRef -SpecifiedTest $SpecifiedTest

if ($AsJson.IsPresent) {
    $plan | ConvertTo-Json -Depth 5
    return
}

$plan
