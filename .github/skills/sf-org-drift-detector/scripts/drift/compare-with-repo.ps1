<#
.SYNOPSIS
Compares retrieved org metadata with the repository source.

.DESCRIPTION
Builds a normalized file inventory for monitored metadata and reports additions,
deletions, and content mismatches between the repo and the retrieved org source.

.EXAMPLE
.\compare-with-repo.ps1 -RetrievedPath .sf\drift\retrieved
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string]$RetrievedPath = '.sf\drift\retrieved',

    [Parameter()]
    [string]$OutputPath = '.sf\drift\drift-report.json',

    [Parameter()]
    [switch]$AsJson
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..\scripts\salesforce\SalesforceCopilotUtils.psm1') -Force

function Resolve-DriftSourceRoot {
    param(
        [Parameter(Mandatory)]
        [string]$BasePath
    )

    foreach ($candidate in @(
        (Join-Path -Path $BasePath -ChildPath 'force-app\main\default'),
        (Join-Path -Path $BasePath -ChildPath 'main\default'),
        $BasePath
    )) {
        if (Test-Path -Path $candidate) {
            return $candidate
        }
    }

    throw "Unable to locate a retrieved source root under '$BasePath'."
}

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

function Get-DriftFileInventory {
    param(
        [Parameter(Mandatory)]
        [string]$RootPath
    )

    $patterns = @(
        'classes\*.cls',
        'classes\*.cls-meta.xml',
        'triggers\*.trigger',
        'triggers\*.trigger-meta.xml',
        'flows\*.flow-meta.xml',
        'layouts\*.layout-meta.xml',
        'permissionsets\*.permissionset-meta.xml',
        'profiles\*.profile-meta.xml',
        'objects\**\*.xml'
    )

    $inventory = New-Object 'System.Collections.Generic.Dictionary[string, string]'

    foreach ($pattern in $patterns) {
        foreach ($file in Get-ChildItem -Path $RootPath -Recurse -File -Include ([System.IO.Path]::GetFileName($pattern))) {
            $relativePath = $file.FullName.Substring($RootPath.Length).TrimStart('\')

            if (-not $inventory.ContainsKey($relativePath)) {
                $inventory.Add($relativePath, $file.FullName)
            }
        }
    }

    $inventory
}

function Get-NormalizedFileText {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    ((Get-Content -Path $Path -Raw) -replace "`r`n", "`n").Trim()
}

$repositoryRoot = Get-RepositoryRoot
$repoSourceRoot = Join-Path -Path $repositoryRoot -ChildPath 'force-app\main\default'
$retrievedSourceRoot = Resolve-DriftSourceRoot -BasePath (Resolve-RepoPath -RepositoryRoot $repositoryRoot -Path $RetrievedPath)
$repoInventory = Get-DriftFileInventory -RootPath $repoSourceRoot
$retrievedInventory = Get-DriftFileInventory -RootPath $retrievedSourceRoot
$allRelativePaths = @($repoInventory.Keys + $retrievedInventory.Keys | Sort-Object -Unique)

$findings = @(foreach ($relativePath in $allRelativePaths) {
    $inRepo = $repoInventory.ContainsKey($relativePath)
    $inOrg = $retrievedInventory.ContainsKey($relativePath)

    if ($inRepo -and -not $inOrg) {
        [PSCustomObject]@{
            Status       = 'MissingInOrg'
            RelativePath = $relativePath.Replace('\', '/')
        }
        continue
    }

    if (-not $inRepo -and $inOrg) {
        [PSCustomObject]@{
            Status       = 'MissingInRepo'
            RelativePath = $relativePath.Replace('\', '/')
        }
        continue
    }

    $repoText = Get-NormalizedFileText -Path $repoInventory[$relativePath]
    $orgText = Get-NormalizedFileText -Path $retrievedInventory[$relativePath]

    if ($repoText -ne $orgText) {
        [PSCustomObject]@{
            Status       = 'DifferentContent'
            RelativePath = $relativePath.Replace('\', '/')
        }
    }
})

$outputFullPath = Resolve-RepoPath -RepositoryRoot $repositoryRoot -Path $OutputPath
$outputDirectory = Split-Path -Path $outputFullPath -Parent

if (-not (Test-Path -Path $outputDirectory)) {
    New-Item -Path $outputDirectory -ItemType Directory -Force | Out-Null
}

$jsonOutput = if ($findings.Count -eq 0) { '[]' } else { $findings | ConvertTo-Json -Depth 5 }
Set-Content -Path $outputFullPath -Value $jsonOutput -Encoding UTF8

if ($AsJson.IsPresent) {
    $jsonOutput
    return
}

Write-Output ("Compared repo source to retrieved org metadata. Drift findings: {0}" -f $findings.Count)
$findings | Sort-Object Status, RelativePath
