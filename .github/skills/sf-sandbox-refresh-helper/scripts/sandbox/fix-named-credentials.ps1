<#
.SYNOPSIS
Deploys sandbox-safe integration metadata after a refresh.

.DESCRIPTION
Deploys a manifest or metadata list for named credentials, external credentials,
and custom metadata, then optionally executes a post-refresh Apex script.

.EXAMPLE
.\fix-named-credentials.ps1 -TargetOrg my-sandbox
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$TargetOrg,

    [Parameter()]
    [string]$ConfigRoot,

    [Parameter()]
    [string[]]$Metadata = @('NamedCredential', 'ExternalCredential', 'CustomMetadata'),

    [Parameter()]
    [switch]$DryRun
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..\scripts\salesforce\SalesforceCopilotUtils.psm1') -Force

if ([string]::IsNullOrWhiteSpace($ConfigRoot)) {
    $ConfigRoot = Get-SandboxConfigRootRelativePath
}

if (-not (Get-Command -Name sf -ErrorAction SilentlyContinue)) {
    throw 'Salesforce CLI (sf) was not found in PATH.'
}

$repositoryRoot = Get-RepositoryRoot
$configFullRoot = Join-Path -Path $repositoryRoot -ChildPath $ConfigRoot
$manifestPath = Join-Path -Path $configFullRoot -ChildPath 'post-refresh-package.xml'
$apexPath = Join-Path -Path $configFullRoot -ChildPath 'post-refresh.apex'

$deployArguments = New-Object 'System.Collections.Generic.List[string]'
foreach ($value in @('project', 'deploy', 'start', '--target-org', $TargetOrg, '--test-level', 'NoTestRun', '--wait', '20')) {
    $deployArguments.Add($value)
}

if (Test-Path -Path $manifestPath) {
    $deployArguments.Add('--manifest')
    $deployArguments.Add($manifestPath)
} else {
    foreach ($metadataMember in $Metadata) {
        $deployArguments.Add('--metadata')
        $deployArguments.Add($metadataMember)
    }
}

Write-Output ('Deploy command: sf ' + ($deployArguments -join ' '))

if (-not $DryRun.IsPresent) {
    & sf @deployArguments
}

if (Test-Path -Path $apexPath) {
    Write-Output ("Post-refresh Apex script detected: {0}" -f $apexPath)

    if (-not $DryRun.IsPresent) {
        & sf apex run --target-org $TargetOrg --file $apexPath
    }
}
