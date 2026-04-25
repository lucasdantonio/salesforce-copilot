<#
.SYNOPSIS
Flags changed custom fields that may need permission updates.

.DESCRIPTION
Looks for custom field metadata changes and warns when there is no matching
permission set or profile update in the same diff, or when the field does not
appear anywhere in existing access metadata.

.EXAMPLE
.\check-missing-permset-fields.ps1 -BaseRef origin/main -HeadRef HEAD
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

$entries = @(Get-GitDiffEntry -BaseRef $BaseRef -HeadRef $HeadRef)
$fieldDescriptors = @(
    $entries |
        ForEach-Object { Get-SalesforceMetadataDescriptor -Path $_.Path } |
        Where-Object { $null -ne $_ -and $_.Type -eq 'CustomField' } |
        Sort-Object Member -Unique
)

if ($fieldDescriptors.Count -eq 0) {
    Write-Output 'No changed custom fields were found.'
    return
}

$permissionMetadataChanged = $entries.Path -match '^force-app/main/default/(permissionsets|profiles)/'
$repositoryRoot = Get-RepositoryRoot
$accessFiles = Get-ChildItem -Path (Join-Path -Path $repositoryRoot -ChildPath 'force-app\main\default') -Recurse -File -Include '*.permissionset-meta.xml', '*.profile-meta.xml'

$findings = @(foreach ($field in $fieldDescriptors) {
    $fieldFound = Select-String -Path $accessFiles.FullName -Pattern ([regex]::Escape($field.Member)) -Quiet

    if (-not $fieldFound -or -not $permissionMetadataChanged) {
        [PSCustomObject]@{
            Field                    = $field.Member
            PermissionMetadataChanged = [bool]$permissionMetadataChanged
            FieldReferencedSomewhere = [bool]$fieldFound
        }
    }
})

if ($findings.Count -eq 0) {
    Write-Output 'All changed fields already have visible permission coverage.'
    return
}

Write-Warning ("Found {0} custom field(s) that may need permission review." -f $findings.Count)
$findings
