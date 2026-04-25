<#
.SYNOPSIS
Prints a drift summary from a retrieved org comparison.

.DESCRIPTION
Reads the JSON comparison report or generates one on the fly, then prints a
grouped summary by drift status and metadata type.

.EXAMPLE
.\report-drift.ps1 -RetrievedPath .sf\drift\retrieved
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string]$RetrievedPath = '.sf\drift\retrieved',

    [Parameter()]
    [string]$CompareResultPath = '.sf\drift\drift-report.json',

    [Parameter()]
    [switch]$AsJson
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..\scripts\salesforce\SalesforceCopilotUtils.psm1') -Force

function Resolve-RepoPath {
    param(
        [Parameter(Mandatory)]
        [string]$RepositoryRoot,

        [Parameter(Mandatory)]
        [string]$Path
    )

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return $Path
    }

    Join-Path -Path $RepositoryRoot -ChildPath $Path
}

$repositoryRoot = Get-RepositoryRoot
$compareResultFullPath = Resolve-RepoPath -RepositoryRoot $repositoryRoot -Path $CompareResultPath

if (-not (Test-Path -Path $compareResultFullPath)) {
    & (Join-Path -Path $PSScriptRoot -ChildPath 'compare-with-repo.ps1') -RetrievedPath $RetrievedPath -OutputPath $CompareResultPath | Out-Null
}

$jsonText = Get-Content -Path $compareResultFullPath -Raw
$findings = if ([string]::IsNullOrWhiteSpace($jsonText)) { @() } else { @((ConvertFrom-Json -InputObject $jsonText)) }

$summary = @(foreach ($finding in $findings) {
    $descriptor = Get-SalesforceMetadataDescriptor -Path ('force-app/main/default/' + $finding.RelativePath.Replace('\', '/'))
    [PSCustomObject]@{
        Status       = $finding.Status
        MetadataType = if ($null -ne $descriptor) { $descriptor.Type } else { 'Unknown' }
        RelativePath = $finding.RelativePath
    }
})

if ($AsJson.IsPresent) {
    $summary | ConvertTo-Json -Depth 5
    return
}

Write-Output ("Drift findings: {0}" -f $summary.Count)
$summary | Group-Object -Property Status, MetadataType | Sort-Object Name | ForEach-Object {
    [PSCustomObject]@{
        Status       = $_.Group[0].Status
        MetadataType = $_.Group[0].MetadataType
        Count        = $_.Count
    }
}

if ($summary.Count -gt 0) {
    Write-Output ''
    $summary | Sort-Object Status, MetadataType, RelativePath
}
