<#
.SYNOPSIS
Prints a human-readable Apex test plan.

.DESCRIPTION
Builds the recommended test plan and prints the chosen mode, reason, and any
selected test class names.

.EXAMPLE
.\print-test-plan.ps1 -BaseRef origin/main -HeadRef HEAD
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
    [string[]]$SpecifiedTest
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\scripts\salesforce\ApexTestCopilotUtils.psm1') -Force

$plan = Get-ApexTestPlan -Mode $Mode -BaseRef $BaseRef -HeadRef $HeadRef -SpecifiedTest $SpecifiedTest
$selectedTests = @($plan.Tests)

Write-Output ("Mode   : {0}" -f $plan.Mode)
Write-Output ("Reason : {0}" -f $plan.Reason)

if ($selectedTests.Count -gt 0) {
    Write-Output 'Tests  :'
    $selectedTests | ForEach-Object { Write-Output ("- {0}" -f $_) }
}
