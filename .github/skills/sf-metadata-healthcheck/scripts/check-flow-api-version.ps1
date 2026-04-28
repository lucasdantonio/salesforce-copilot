<#
.SYNOPSIS
Checks Flow API versions against the repo package version.

.DESCRIPTION
Warns when changed Flows use a different API version than the repository package
version so version drift is visible before deployment.

.EXAMPLE
.\check-flow-api-version.ps1 -BaseRef origin/main -HeadRef HEAD
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string]$BaseRef = 'HEAD~1',

    [Parameter()]
    [string]$HeadRef = 'HEAD'
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\scripts\salesforce\SalesforceCopilotUtils.psm1') -Force

$targetVersion = [decimal](Get-DefaultPackageVersion)
$metadataRootPattern = [regex]::Escape((Get-MetadataRootRelativePath))
$changedFlows = @(
    Get-GitDiffEntry -BaseRef $BaseRef -HeadRef $HeadRef |
        Where-Object { $_.Path -match "^$metadataRootPattern/flows/.+\.flow-meta\.xml$" } |
        Select-Object -ExpandProperty Path -Unique
)

if ($changedFlows.Count -eq 0) {
    Write-Output 'No changed flow metadata was found.'
    return
}

$findings = @(foreach ($flowPath in $changedFlows) {
    $fullPath = Join-Path -Path (Get-RepositoryRoot) -ChildPath $flowPath

    if (-not (Test-Path -Path $fullPath)) {
        continue
    }

    [xml]$flowXml = Get-Content -Path $fullPath -Raw
    $flowVersion = [decimal]$flowXml.Flow.apiVersion

    if ($flowVersion -ne $targetVersion) {
        [PSCustomObject]@{
            FlowPath        = $flowPath
            FlowApiVersion  = $flowVersion
            PackageVersion  = $targetVersion
        }
    }
})

if ($findings.Count -eq 0) {
    Write-Output ("All changed flows match the package version {0}." -f $targetVersion)
    return
}

Write-Warning ("Found {0} flow file(s) with API version drift." -f $findings.Count)
$findings
