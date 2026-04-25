<#
.SYNOPSIS
Loads sandbox seed data from a tree import plan.

.DESCRIPTION
Imports seed data with Salesforce CLI when a seed-data-plan.json file is present.

.EXAMPLE
.\load-seed-data.ps1 -TargetOrg my-sandbox
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$TargetOrg,

    [Parameter()]
    [string]$PlanPath = 'config\sandbox\seed-data-plan.json',

    [Parameter()]
    [switch]$DryRun
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..\scripts\salesforce\SalesforceCopilotUtils.psm1') -Force

$repositoryRoot = Get-RepositoryRoot
$planFullPath = Join-Path -Path $repositoryRoot -ChildPath $PlanPath

if (-not (Test-Path -Path $planFullPath)) {
    Write-Warning ("Seed data plan not found: {0}" -f $planFullPath)
    return
}

Write-Output ("Import command: sf data import tree --target-org {0} --plan {1}" -f $TargetOrg, $planFullPath)

if (-not $DryRun.IsPresent) {
    & sf data import tree --target-org $TargetOrg --plan $planFullPath
}
