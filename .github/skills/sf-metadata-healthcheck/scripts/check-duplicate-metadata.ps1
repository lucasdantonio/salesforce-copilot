<#
.SYNOPSIS
Checks for duplicate Salesforce metadata members in source.

.DESCRIPTION
Scans canonical source artifacts and bundle folders to find duplicate metadata
members of the same type within the repository.

.EXAMPLE
.\check-duplicate-metadata.ps1
#>
[CmdletBinding()]
param()

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\scripts\salesforce\SalesforceCopilotUtils.psm1') -Force

$repositoryRoot = Get-RepositoryRoot
$sourceRoot = Join-Path -Path $repositoryRoot -ChildPath (Get-MetadataRootRelativePath)

$filePatterns = @(
    '*.cls',
    '*.trigger',
    '*.page',
    '*.component',
    '*.flow-meta.xml',
    '*.flowDefinition-meta.xml',
    '*.permissionset-meta.xml',
    '*.profile-meta.xml',
    '*.layout-meta.xml',
    '*.tab-meta.xml',
    '*.flexipage-meta.xml',
    '*.messageChannel-meta.xml',
    '*.asset-meta.xml',
    '*.resource-meta.xml',
    '*.app-meta.xml',
    '*.field-meta.xml',
    '*.recordType-meta.xml',
    '*.validationRule-meta.xml',
    '*.listView-meta.xml',
    '*.compactLayout-meta.xml',
    '*.businessProcess-meta.xml',
    '*.sharingReason-meta.xml',
    '*.webLink-meta.xml',
    '*.object-meta.xml',
    'CustomLabels.labels-meta.xml'
)

$descriptorIndex = New-Object 'System.Collections.Generic.List[object]'

foreach ($pattern in $filePatterns) {
    foreach ($file in Get-ChildItem -Path $sourceRoot -Recurse -File -Filter $pattern -ErrorAction SilentlyContinue) {
        $descriptor = Get-SalesforceMetadataDescriptor -Path $file.FullName

        if ($null -ne $descriptor) {
            $descriptorIndex.Add([PSCustomObject]@{
                Key  = $descriptor.Key
                Type = $descriptor.Type
                Member = $descriptor.Member
                Path = $descriptor.RelativePath
            })
        }
    }
}

foreach ($bundleRoot in @('lwc', 'aura')) {
    $bundlePath = Join-Path -Path $sourceRoot -ChildPath $bundleRoot

    if (-not (Test-Path -Path $bundlePath)) {
        continue
    }

    foreach ($directory in Get-ChildItem -Path $bundlePath -Directory) {
        $descriptor = Get-SalesforceMetadataDescriptor -Path $directory.FullName

        if ($null -ne $descriptor) {
            $descriptorIndex.Add([PSCustomObject]@{
                Key    = $descriptor.Key
                Type   = $descriptor.Type
                Member = $descriptor.Member
                Path   = $descriptor.RelativePath
            })
        }
    }
}

$findings = @(foreach ($group in $descriptorIndex | Group-Object -Property Key) {
    if ($group.Count -gt 1) {
        [PSCustomObject]@{
            Type   = $group.Group[0].Type
            Member = $group.Group[0].Member
            Paths  = ($group.Group.Path | Sort-Object -Unique) -join '; '
        }
    }
})

if ($findings.Count -eq 0) {
    Write-Output 'No duplicate metadata members were found.'
    return
}

Write-Warning ("Found {0} duplicate metadata member definition(s)." -f $findings.Count)
$findings | Sort-Object Type, Member
