<#
.SYNOPSIS
Runs the standard sandbox post-refresh automation flow.

.DESCRIPTION
Executes the configured post-refresh steps in order: integration metadata fix,
integration user creation, permission assignment, and seed data import.

.EXAMPLE
.\post-refresh.ps1 -TargetOrg my-sandbox
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$TargetOrg,

    [Parameter()]
    [string]$ConfigRoot,

    [Parameter()]
    [switch]$SkipIntegrationMetadata,

    [Parameter()]
    [switch]$SkipIntegrationUsers,

    [Parameter()]
    [switch]$SkipPermsets,

    [Parameter()]
    [switch]$SkipSeedData,

    [Parameter()]
    [switch]$DryRun
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..\scripts\salesforce\SalesforceCopilotUtils.psm1') -Force

if ([string]::IsNullOrWhiteSpace($ConfigRoot)) {
    $ConfigRoot = Get-SandboxConfigRootRelativePath
}

if (-not $SkipIntegrationMetadata.IsPresent) {
    & (Join-Path -Path $PSScriptRoot -ChildPath 'fix-named-credentials.ps1') -TargetOrg $TargetOrg -ConfigRoot $ConfigRoot -DryRun:$DryRun.IsPresent
}

if (-not $SkipIntegrationUsers.IsPresent) {
    & (Join-Path -Path $PSScriptRoot -ChildPath 'create-integration-users.ps1') -TargetOrg $TargetOrg -ConfigPath (Join-Path -Path $ConfigRoot -ChildPath 'integration-users.json') -DryRun:$DryRun.IsPresent
}

if (-not $SkipPermsets.IsPresent) {
    & (Join-Path -Path $PSScriptRoot -ChildPath 'assign-permsets.ps1') -TargetOrg $TargetOrg -ConfigPath (Join-Path -Path $ConfigRoot -ChildPath 'permset-assignments.json') -DryRun:$DryRun.IsPresent
}

if (-not $SkipSeedData.IsPresent) {
    & (Join-Path -Path $PSScriptRoot -ChildPath 'load-seed-data.ps1') -TargetOrg $TargetOrg -PlanPath (Join-Path -Path $ConfigRoot -ChildPath 'seed-data-plan.json') -DryRun:$DryRun.IsPresent
}
