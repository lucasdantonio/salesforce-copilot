Set-StrictMode -Version 3.0

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'SalesforceCopilotUtils.psm1') -Force

function Get-ApexClassInventory {
    $repositoryRoot = Get-RepositoryRoot
    $classRoot = Join-Path -Path $repositoryRoot -ChildPath (Join-Path -Path (Get-MetadataRootRelativePath) -ChildPath 'classes')

    if (-not (Test-Path -Path $classRoot)) {
        return @()
    }

    foreach ($file in Get-ChildItem -Path $classRoot -Filter '*.cls' -File) {
        $content = Get-Content -Path $file.FullName -Raw
        $isTest = $content -match '@isTest' -or $file.BaseName -match '(^Test|Test$)'

        [PSCustomObject]@{
            Name     = $file.BaseName
            Path     = $file.FullName
            Content  = $content
            IsTest   = $isTest
            Relative = Get-NormalizedRelativePath -Path $file.FullName
        }
    }
}

function Find-RelatedApexTest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$ChangedPath
    )

    $inventory = @(Get-ApexClassInventory)
    $tests = @($inventory | Where-Object { $_.IsTest })
    $candidates = New-Object 'System.Collections.Generic.HashSet[string]'
    $metadataRootPattern = [regex]::Escape((Get-MetadataRootRelativePath))

    foreach ($path in $ChangedPath) {
        $relativePath = Get-NormalizedRelativePath -Path $path
        $descriptor = Get-SalesforceMetadataDescriptor -Path $relativePath
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($relativePath)

        if ($relativePath -match "^$metadataRootPattern/classes/([^/]+)\.cls$") {
            $baseName = $Matches[1]
        } elseif ($relativePath -match "^$metadataRootPattern/triggers/([^/]+)\.trigger$") {
            $baseName = $Matches[1]
        }

        foreach ($test in $tests) {
            if ($relativePath -eq $test.Relative) {
                $null = $candidates.Add($test.Name)
                continue
            }

            if ($test.Name -eq ('Test{0}' -f $baseName) -or $test.Name -eq ('{0}Test' -f $baseName)) {
                $null = $candidates.Add($test.Name)
                continue
            }

            if ($test.Name -like ('*{0}*' -f $baseName)) {
                $null = $candidates.Add($test.Name)
                continue
            }

            if ($test.Content -match ("(?<![A-Za-z0-9_]){0}(?![A-Za-z0-9_])" -f [regex]::Escape($baseName))) {
                $null = $candidates.Add($test.Name)
            }
        }

        if ($null -ne $descriptor -and $descriptor.Type -eq 'ApexClass' -and $baseName -match '(^Test|Test$)') {
            $null = $candidates.Add($baseName)
        }
    }

    $candidates.ToArray() | Sort-Object
}

function Get-ApexTestPlan {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('auto', 'all-local', 'specified', 'changed-related', 'none')]
        [string]$Mode = 'auto',

        [Parameter()]
        [string]$BaseRef = 'HEAD~1',

        [Parameter()]
        [string]$HeadRef = 'HEAD',

        [Parameter()]
        [string[]]$SpecifiedTest
    )

    $specifiedTests = @($SpecifiedTest | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

    if ($specifiedTests.Count -gt 0 -and $Mode -eq 'auto') {
        return [PSCustomObject]@{
            Mode   = 'specified'
            Reason = 'Tests were explicitly provided.'
            Tests  = @($specifiedTests | Sort-Object -Unique)
        }
    }

    if ($Mode -eq 'specified') {
        return [PSCustomObject]@{
            Mode   = 'specified'
            Reason = 'Specified mode was requested explicitly.'
            Tests  = @($specifiedTests | Sort-Object -Unique)
        }
    }

    if ($Mode -eq 'all-local') {
        return [PSCustomObject]@{
            Mode   = 'all-local'
            Reason = 'All-local mode was requested explicitly.'
            Tests  = @()
        }
    }

    if ($Mode -eq 'none') {
        return [PSCustomObject]@{
            Mode   = 'none'
            Reason = 'No test execution was requested.'
            Tests  = @()
        }
    }

    $entries = @(Get-GitDiffEntry -BaseRef $BaseRef -HeadRef $HeadRef)
    $changedPaths = @($entries.Path)
    $metadataRootPattern = [regex]::Escape((Get-MetadataRootRelativePath))

    $relevantPaths = @(
        $changedPaths | Where-Object {
            $_ -match "^$metadataRootPattern/(classes|triggers|pages|components|lwc|aura|flows|objects|permissionsets|profiles|layouts)/"
        }
    )

    if ($relevantPaths.Count -eq 0) {
        return [PSCustomObject]@{
            Mode   = 'none'
            Reason = 'No metadata with likely Apex impact changed.'
            Tests  = @()
        }
    }

    $allTestFiles = @(Get-ApexClassInventory | Where-Object { $_.IsTest })
    $changedTestNames = @(
        $entries |
            Where-Object { $_.Path -match "^$metadataRootPattern/classes/([^/]+)\.cls$" } |
            ForEach-Object {
                if ($_.Path -match "^$metadataRootPattern/classes/([^/]+)\.cls$") {
                    $Matches[1]
                }
            } |
            Where-Object { $_ -in $allTestFiles.Name } |
            Sort-Object -Unique
    )

    if ($changedTestNames.Count -gt 0 -and $relevantPaths.Count -le 5) {
        return [PSCustomObject]@{
            Mode   = 'specified'
            Reason = 'Only a small set of test classes changed directly.'
            Tests  = @($changedTestNames)
        }
    }

    $broadImpact = $false
    if ($relevantPaths.Count -gt 20) {
        $broadImpact = $true
    }

    if ($changedPaths -match "^$metadataRootPattern/triggers/" -or
        $changedPaths -match "^$metadataRootPattern/objects/" -or
        $changedPaths -match "^$metadataRootPattern/flows/") {
        $broadImpact = $true
    }

    if ($changedPaths -match "^$metadataRootPattern/classes/(TriggerHandler|fflib_).+\.cls$") {
        $broadImpact = $true
    }

    if ($broadImpact) {
        return [PSCustomObject]@{
            Mode   = 'all-local'
            Reason = 'Broad-impact metadata changed, so local Apex coverage is safer.'
            Tests  = @()
        }
    }

    $relatedTests = @(Find-RelatedApexTest -ChangedPath $relevantPaths)

    if ($relatedTests.Count -eq 0) {
        return [PSCustomObject]@{
            Mode   = 'all-local'
            Reason = 'No related tests were discovered safely, so all-local is the fallback.'
            Tests  = @()
        }
    }

    [PSCustomObject]@{
        Mode   = 'changed-related'
        Reason = 'Related tests were discovered from changed metadata and class references.'
        Tests  = @($relatedTests)
    }
}

Export-ModuleMember -Function Get-ApexClassInventory, Find-RelatedApexTest, Get-ApexTestPlan
