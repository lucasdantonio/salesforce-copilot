<#
.SYNOPSIS
Retrieves monitored Salesforce metadata from an org for drift detection.

.DESCRIPTION
Builds a temporary manifest for high-risk shared metadata and retrieves it into
an isolated output folder using Salesforce CLI.

.EXAMPLE
.\retrieve-org-metadata.ps1 -TargetOrg my-sandbox
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$TargetOrg,

    [Parameter()]
    [string]$OutputPath = '.sf\drift\retrieved',

    [Parameter()]
    [int]$WaitMinutes = 20
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..\scripts\salesforce\SalesforceCopilotUtils.psm1') -Force

if (-not (Get-Command -Name sf -ErrorAction SilentlyContinue)) {
    throw 'Salesforce CLI (sf) was not found in PATH.'
}

$repositoryRoot = Get-RepositoryRoot
$outputFullPath = Join-Path -Path $repositoryRoot -ChildPath $OutputPath
$manifestPath = Join-Path -Path $outputFullPath -ChildPath 'package.xml'
$packageVersion = Get-DefaultPackageVersion -RepositoryRoot $repositoryRoot

if (Test-Path -Path $outputFullPath) {
    Remove-Item -Path $outputFullPath -Recurse -Force
}

New-Item -Path $outputFullPath -ItemType Directory -Force | Out-Null

$manifestMetadata = @(
    [PSCustomObject]@{ Type = 'ApexClass'; Member = '*' },
    [PSCustomObject]@{ Type = 'ApexTrigger'; Member = '*' },
    [PSCustomObject]@{ Type = 'Flow'; Member = '*' },
    [PSCustomObject]@{ Type = 'Layout'; Member = '*' },
    [PSCustomObject]@{ Type = 'PermissionSet'; Member = '*' },
    [PSCustomObject]@{ Type = 'Profile'; Member = '*' },
    [PSCustomObject]@{ Type = 'CustomObject'; Member = '*' },
    [PSCustomObject]@{ Type = 'CustomField'; Member = '*' },
    [PSCustomObject]@{ Type = 'RecordType'; Member = '*' },
    [PSCustomObject]@{ Type = 'ValidationRule'; Member = '*' }
)

$manifestContent = New-PackageXmlContent -Metadata $manifestMetadata -Version $packageVersion
Set-Content -Path $manifestPath -Value $manifestContent -Encoding UTF8

$arguments = @(
    'project', 'retrieve', 'start',
    '--target-org', $TargetOrg,
    '--manifest', $manifestPath,
    '--output-dir', $outputFullPath,
    '--ignore-conflicts',
    '--wait', $WaitMinutes
)

& sf @arguments

[PSCustomObject]@{
    TargetOrg    = $TargetOrg
    ManifestPath = $manifestPath
    OutputPath   = $outputFullPath
}
