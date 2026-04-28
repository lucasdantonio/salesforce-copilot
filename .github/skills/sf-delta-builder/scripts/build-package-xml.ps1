<#
.SYNOPSIS
Builds a package.xml file from changed Salesforce metadata.

.DESCRIPTION
Maps added, modified, copied, and renamed metadata files to Salesforce metadata
members and writes a generated package.xml file.

.EXAMPLE
.\build-package-xml.ps1 -BaseRef origin/main -HeadRef HEAD -OutputPath manifest/package.delta.xml
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string]$BaseRef = 'HEAD~1',

    [Parameter()]
    [string]$HeadRef = 'HEAD',

    [Parameter()]
    [string]$OutputPath,

    [Parameter()]
    [switch]$IncludeUntracked
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\scripts\salesforce\SalesforceCopilotUtils.psm1') -Force

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = (Join-Path -Path (Get-ManifestDirectoryRelativePath) -ChildPath 'package.delta.xml')
}

$metadata = @(Get-ChangedMetadataDescriptor -BaseRef $BaseRef -HeadRef $HeadRef -IncludeUntracked:$IncludeUntracked.IsPresent |
    Where-Object { $_.Status -in @('A', 'M', 'C', 'R') } |
    Sort-Object Type, Member -Unique)

if ($metadata.Count -eq 0) {
    Write-Warning 'No deployable metadata changes were found for package.xml generation.'
    return
}

$outputFullPath = Join-Path -Path (Get-RepositoryRoot) -ChildPath $OutputPath
$outputDirectory = Split-Path -Path $outputFullPath -Parent

if (-not (Test-Path -Path $outputDirectory)) {
    New-Item -Path $outputDirectory -ItemType Directory -Force | Out-Null
}

$packageXml = New-PackageXmlContent -Metadata $metadata
Set-Content -Path $outputFullPath -Value $packageXml -Encoding UTF8

Write-Output ("Wrote {0} metadata member(s) to {1}." -f $metadata.Count, $outputFullPath)
$metadata | Group-Object -Property Type | Sort-Object Name | ForEach-Object {
    [PSCustomObject]@{
        Type    = $_.Name
        Members = $_.Count
    }
}
