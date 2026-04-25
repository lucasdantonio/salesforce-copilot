<#
.SYNOPSIS
Flags destructive manifest entries without a matching deleted metadata file.

.DESCRIPTION
Parses destructiveChanges manifests and compares them to deleted or renamed
metadata in the current diff. Entries without a matching source deletion are
flagged for manual review.

.EXAMPLE
.\check-destructive-without-backup.ps1 -BaseRef origin/main -HeadRef HEAD
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

$repositoryRoot = Get-RepositoryRoot
$deletedKeys = New-Object 'System.Collections.Generic.HashSet[string]'

foreach ($entry in Get-GitDiffEntry -BaseRef $BaseRef -HeadRef $HeadRef) {
    if ($entry.Status -eq 'D') {
        $descriptor = Get-SalesforceMetadataDescriptor -Path $entry.Path

        if ($null -ne $descriptor) {
            $null = $deletedKeys.Add($descriptor.Key)
        }
    }

    if ($entry.Status -eq 'R') {
        $previousDescriptor = Get-SalesforceMetadataDescriptor -Path $entry.PreviousPath
        $currentDescriptor = Get-SalesforceMetadataDescriptor -Path $entry.Path

        if ($null -ne $previousDescriptor -and $null -ne $currentDescriptor -and $previousDescriptor.Key -ne $currentDescriptor.Key) {
            $null = $deletedKeys.Add($previousDescriptor.Key)
        }
    }
}

$manifests = Get-ChildItem -Path (Join-Path -Path $repositoryRoot -ChildPath 'manifest') -Filter 'destructiveChanges*.xml' -File -ErrorAction SilentlyContinue

if ($manifests.Count -eq 0) {
    Write-Output 'No destructiveChanges manifests were found.'
    return
}

$findings = @(foreach ($manifest in $manifests) {
    [xml]$manifestXml = Get-Content -Path $manifest.FullName -Raw

    foreach ($typeNode in $manifestXml.Package.types) {
        foreach ($memberNode in $typeNode.members) {
            $key = '{0}|{1}' -f [string]$typeNode.name, [string]$memberNode

            if (-not $deletedKeys.Contains($key)) {
                [PSCustomObject]@{
                    Manifest = $manifest.Name
                    Type     = [string]$typeNode.name
                    Member   = [string]$memberNode
                }
            }
        }
    }
})

if ($findings.Count -eq 0) {
    Write-Output 'All destructive manifest entries map to a deleted or renamed metadata member in the current diff.'
    return
}

Write-Warning ("Found {0} destructive entry or entries without a matching deleted source file in the diff." -f $findings.Count)
$findings | Sort-Object Manifest, Type, Member
