<#
.SYNOPSIS
Builds a destructiveChanges manifest from deleted Salesforce metadata.

.DESCRIPTION
Maps deleted metadata files, and renamed metadata when the member name changes,
to destructiveChanges members and writes a generated destructiveChanges manifest.

.EXAMPLE
.\build-destructive-changes.ps1 -BaseRef origin/main -HeadRef HEAD -OutputPath manifest/destructiveChangesPost.delta.xml
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string]$BaseRef = 'HEAD~1',

    [Parameter()]
    [string]$HeadRef = 'HEAD',

    [Parameter()]
    [string]$OutputPath
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\scripts\salesforce\SalesforceCopilotUtils.psm1') -Force

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = (Join-Path -Path (Get-ManifestDirectoryRelativePath) -ChildPath 'destructiveChangesPost.delta.xml')
}

$destructiveMetadata = New-Object 'System.Collections.Generic.List[object]'

foreach ($entry in Get-GitDiffEntry -BaseRef $BaseRef -HeadRef $HeadRef) {
    if ($entry.Status -eq 'D') {
        $deletedDescriptor = Get-SalesforceMetadataDescriptor -Path $entry.Path

        if ($null -ne $deletedDescriptor) {
            $destructiveMetadata.Add($deletedDescriptor)
        }

        continue
    }

    if ($entry.Status -eq 'R') {
        $previousDescriptor = Get-SalesforceMetadataDescriptor -Path $entry.PreviousPath
        $currentDescriptor = Get-SalesforceMetadataDescriptor -Path $entry.Path

        if ($null -ne $previousDescriptor -and $null -ne $currentDescriptor) {
            if ($previousDescriptor.Key -ne $currentDescriptor.Key) {
                $destructiveMetadata.Add($previousDescriptor)
            }
        }
    }
}

$metadata = @($destructiveMetadata | Sort-Object Type, Member -Unique)

if ($metadata.Count -eq 0) {
    Write-Warning 'No destructive metadata changes were found.'
    return
}

$outputFullPath = Join-Path -Path (Get-RepositoryRoot) -ChildPath $OutputPath
$outputDirectory = Split-Path -Path $outputFullPath -Parent

if (-not (Test-Path -Path $outputDirectory)) {
    New-Item -Path $outputDirectory -ItemType Directory -Force | Out-Null
}

$packageXml = New-PackageXmlContent -Metadata $metadata
Set-Content -Path $outputFullPath -Value $packageXml -Encoding UTF8

Write-Output ("Wrote {0} destructive member(s) to {1}." -f $metadata.Count, $outputFullPath)
$metadata | Group-Object -Property Type | Sort-Object Name | ForEach-Object {
    [PSCustomObject]@{
        Type    = $_.Name
        Members = $_.Count
    }
}
