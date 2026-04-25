<#
.SYNOPSIS
Runs Salesforce Apex tests based on a selected test plan.

.DESCRIPTION
Builds an Apex test plan and executes the corresponding Salesforce CLI command,
or prints the command in dry-run mode.

.EXAMPLE
.\run-apex-tests.ps1 -BaseRef origin/main -HeadRef HEAD -DryRun
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
    [string]$TargetOrg,

    [Parameter()]
    [switch]$CodeCoverage,

    [Parameter()]
    [switch]$DryRun
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\scripts\salesforce\ApexTestCopilotUtils.psm1') -Force

$plan = Get-ApexTestPlan -Mode $Mode -BaseRef $BaseRef -HeadRef $HeadRef -SpecifiedTest $SpecifiedTest
$selectedTests = @($plan.Tests)

if ($plan.Mode -eq 'none') {
    Write-Output 'No Apex tests need to run for this change.'
    return
}

if (-not $DryRun.IsPresent -and -not (Get-Command -Name sf -ErrorAction SilentlyContinue)) {
    throw 'Salesforce CLI (sf) was not found in PATH.'
}

$arguments = New-Object 'System.Collections.Generic.List[string]'
foreach ($value in @('apex', 'run', 'test', '--result-format', 'human')) {
    $arguments.Add($value)
}

if ($CodeCoverage.IsPresent) {
    $arguments.Add('--code-coverage')
}

if ($TargetOrg) {
    foreach ($value in @('--target-org', $TargetOrg)) {
        $arguments.Add($value)
    }
}

switch ($plan.Mode) {
    'all-local' {
        foreach ($value in @('--test-level', 'RunLocalTests')) {
            $arguments.Add($value)
        }
    }
    'specified' {
        if ($selectedTests.Count -eq 0) {
            throw 'Specified mode requires at least one Apex test class.'
        }
        $arguments.Add('--test-level')
        $arguments.Add('RunSpecifiedTests')
        foreach ($testName in $selectedTests) {
            $arguments.Add('--class-names')
            $arguments.Add($testName)
        }
    }
    'changed-related' {
        if ($selectedTests.Count -eq 0) {
            throw 'Changed-related mode requires at least one discovered Apex test class.'
        }
        $arguments.Add('--test-level')
        $arguments.Add('RunSpecifiedTests')
        foreach ($testName in $selectedTests) {
            $arguments.Add('--class-names')
            $arguments.Add($testName)
        }
    }
}

$commandText = 'sf ' + ($arguments -join ' ')
Write-Output ("Plan  : {0}" -f $plan.Mode)
Write-Output ("Reason: {0}" -f $plan.Reason)
Write-Output ("Command: {0}" -f $commandText)

if ($DryRun.IsPresent) {
    return
}

& sf @arguments
