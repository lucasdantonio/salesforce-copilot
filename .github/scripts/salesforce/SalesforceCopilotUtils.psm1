Set-StrictMode -Version 3.0

function Normalize-SalesforceCopilotRelativePath {
    param(
        [Parameter()]
        [AllowEmptyString()]
        [string]$Path,

        [Parameter()]
        [string]$Default = ''
    )

    $effectivePath = if ([string]::IsNullOrWhiteSpace($Path)) { $Default } else { $Path }
    $normalizedPath = $effectivePath.Replace('\', '/').Trim()

    if ($normalizedPath.StartsWith('./', [System.StringComparison]::Ordinal)) {
        $normalizedPath = $normalizedPath.Substring(2)
    }

    $normalizedPath.Trim('/')
}

function Get-SalesforceCopilotConfiguration {
    [CmdletBinding()]
    param()

    $metadataRoot = Normalize-SalesforceCopilotRelativePath -Path $env:SALESFORCE_COPILOT_METADATA_ROOT -Default 'force-app/main/default'
    $manifestPath = Normalize-SalesforceCopilotRelativePath -Path $env:SALESFORCE_COPILOT_MANIFEST_PATH -Default 'manifest/package.xml'
    $sandboxConfigRoot = Normalize-SalesforceCopilotRelativePath -Path $env:SALESFORCE_COPILOT_SANDBOX_CONFIG_ROOT -Default 'config/sandbox'
    $workingRoot = Normalize-SalesforceCopilotRelativePath -Path $env:SALESFORCE_COPILOT_WORK_ROOT -Default '.sf/copilot'
    $manifestDirectory = Normalize-SalesforceCopilotRelativePath -Path (Split-Path -Path $manifestPath -Parent)

    if ([string]::IsNullOrWhiteSpace($manifestDirectory)) {
        $manifestDirectory = '.'
    }

    [PSCustomObject]@{
        MetadataRoot      = $metadataRoot
        MetadataRootRegex = '^' + [regex]::Escape($metadataRoot) + '/'
        ManifestPath      = $manifestPath
        ManifestDirectory = $manifestDirectory
        SandboxConfigRoot = $sandboxConfigRoot
        WorkingRoot       = $workingRoot
    }
}

function Get-MetadataRootRelativePath {
    (Get-SalesforceCopilotConfiguration).MetadataRoot
}

function Get-MetadataRootRegex {
    (Get-SalesforceCopilotConfiguration).MetadataRootRegex
}

function Get-ManifestRelativePath {
    (Get-SalesforceCopilotConfiguration).ManifestPath
}

function Get-ManifestDirectoryRelativePath {
    (Get-SalesforceCopilotConfiguration).ManifestDirectory
}

function Get-SandboxConfigRootRelativePath {
    (Get-SalesforceCopilotConfiguration).SandboxConfigRoot
}

function Get-WorkingRootRelativePath {
    (Get-SalesforceCopilotConfiguration).WorkingRoot
}

function Get-RepositoryRoot {
    $repositoryRoot = & git --no-pager rev-parse --show-toplevel 2>$null

    if (-not $repositoryRoot) {
        throw 'Unable to determine the git repository root.'
    }

    return $repositoryRoot.Trim()
}

function Get-DefaultPackageVersion {
    param(
        [Parameter()]
        [string]$RepositoryRoot = (Get-RepositoryRoot)
    )

    $packagePath = Join-Path -Path $RepositoryRoot -ChildPath (Get-ManifestRelativePath)

    if (-not (Test-Path -Path $packagePath)) {
        return '55.0'
    }

    [xml]$packageXml = Get-Content -Path $packagePath -Raw
    $packageXml.Package.version
}

function Get-GitDiffEntry {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$BaseRef = 'HEAD~1',

        [Parameter()]
        [string]$HeadRef = 'HEAD',

        [Parameter()]
        [switch]$IncludeUntracked
    )

    $repositoryRoot = Get-RepositoryRoot
    $diffLines = & git --no-pager -C $repositoryRoot diff --name-status --find-renames=100% $BaseRef $HeadRef -- 2>$null

    foreach ($line in $diffLines) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        $parts = $line -split "`t"
        $statusToken = $parts[0]
        $status = $statusToken.Substring(0, 1)

        if ($status -eq 'R' -or $status -eq 'C') {
            [PSCustomObject]@{
                Status       = $status
                Path         = $parts[2]
                PreviousPath = $parts[1]
            }

            continue
        }

        [PSCustomObject]@{
            Status       = $status
            Path         = $parts[1]
            PreviousPath = $null
        }
    }

    if ($IncludeUntracked.IsPresent) {
        $untrackedFiles = & git --no-pager -C $repositoryRoot ls-files --others --exclude-standard

        foreach ($path in $untrackedFiles) {
            [PSCustomObject]@{
                Status       = 'A'
                Path         = $path
                PreviousPath = $null
            }
        }
    }
}

function Get-NormalizedRelativePath {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $normalizedPath = $Path.Replace('\', '/')
    $repositoryRoot = (Get-RepositoryRoot).Replace('\', '/')

    if ($normalizedPath.StartsWith($repositoryRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $normalizedPath.Substring($repositoryRoot.Length).TrimStart('/')
    }

    if ($normalizedPath.StartsWith('./', [System.StringComparison]::Ordinal)) {
        return $normalizedPath.Substring(2)
    }

    return $normalizedPath.TrimStart('/')
}

function Get-SalesforceMetadataDescriptor {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $relativePath = Get-NormalizedRelativePath -Path $Path

    $config = Get-SalesforceCopilotConfiguration
    $metadataRoot = $config.MetadataRoot
    $metadataRootPattern = [regex]::Escape($metadataRoot)

    if ($relativePath -notlike "$metadataRoot/*") {
        return $null
    }

    $descriptor = $null

    switch -Regex ($relativePath) {
        "^$metadataRootPattern/classes/([^/]+)\.cls(?:-meta\.xml)?$" {
            $descriptor = [PSCustomObject]@{ Type = 'ApexClass'; Member = $Matches[1]; RelativePath = $relativePath }
            break
        }
        "^$metadataRootPattern/triggers/([^/]+)\.trigger(?:-meta\.xml)?$" {
            $descriptor = [PSCustomObject]@{ Type = 'ApexTrigger'; Member = $Matches[1]; RelativePath = $relativePath }
            break
        }
        "^$metadataRootPattern/pages/([^/]+)\.page(?:-meta\.xml)?$" {
            $descriptor = [PSCustomObject]@{ Type = 'ApexPage'; Member = $Matches[1]; RelativePath = $relativePath }
            break
        }
        "^$metadataRootPattern/components/([^/]+)\.component(?:-meta\.xml)?$" {
            $descriptor = [PSCustomObject]@{ Type = 'ApexComponent'; Member = $Matches[1]; RelativePath = $relativePath }
            break
        }
        "^$metadataRootPattern/lwc/([^/]+)/" {
            $descriptor = [PSCustomObject]@{ Type = 'LightningComponentBundle'; Member = $Matches[1]; RelativePath = $relativePath }
            break
        }
        "^$metadataRootPattern/aura/([^/]+)/" {
            $descriptor = [PSCustomObject]@{ Type = 'AuraDefinitionBundle'; Member = $Matches[1]; RelativePath = $relativePath }
            break
        }
        "^$metadataRootPattern/flows/([^/]+)\.flow-meta\.xml$" {
            $descriptor = [PSCustomObject]@{ Type = 'Flow'; Member = $Matches[1]; RelativePath = $relativePath }
            break
        }
        "^$metadataRootPattern/flowDefinitions/([^/]+)\.flowDefinition-meta\.xml$" {
            $descriptor = [PSCustomObject]@{ Type = 'FlowDefinition'; Member = $Matches[1]; RelativePath = $relativePath }
            break
        }
        "^$metadataRootPattern/permissionsets/([^/]+)\.permissionset-meta\.xml$" {
            $descriptor = [PSCustomObject]@{ Type = 'PermissionSet'; Member = $Matches[1]; RelativePath = $relativePath }
            break
        }
        "^$metadataRootPattern/profiles/([^/]+)\.profile-meta\.xml$" {
            $descriptor = [PSCustomObject]@{ Type = 'Profile'; Member = $Matches[1]; RelativePath = $relativePath }
            break
        }
        "^$metadataRootPattern/layouts/([^/]+)\.layout-meta\.xml$" {
            $descriptor = [PSCustomObject]@{ Type = 'Layout'; Member = $Matches[1]; RelativePath = $relativePath }
            break
        }
        "^$metadataRootPattern/tabs/([^/]+)\.tab-meta\.xml$" {
            $descriptor = [PSCustomObject]@{ Type = 'CustomTab'; Member = $Matches[1]; RelativePath = $relativePath }
            break
        }
        "^$metadataRootPattern/flexipages/([^/]+)\.flexipage-meta\.xml$" {
            $descriptor = [PSCustomObject]@{ Type = 'FlexiPage'; Member = $Matches[1]; RelativePath = $relativePath }
            break
        }
        "^$metadataRootPattern/messageChannels/([^/]+)\.messageChannel-meta\.xml$" {
            $descriptor = [PSCustomObject]@{ Type = 'LightningMessageChannel'; Member = $Matches[1]; RelativePath = $relativePath }
            break
        }
        "^$metadataRootPattern/contentassets/([^/]+)\.asset-meta\.xml$" {
            $descriptor = [PSCustomObject]@{ Type = 'ContentAsset'; Member = $Matches[1]; RelativePath = $relativePath }
            break
        }
        "^$metadataRootPattern/staticresources/([^/]+)\.resource-meta\.xml$" {
            $descriptor = [PSCustomObject]@{ Type = 'StaticResource'; Member = $Matches[1]; RelativePath = $relativePath }
            break
        }
        "^$metadataRootPattern/staticresources/([^/]+)\.resource$" {
            $descriptor = [PSCustomObject]@{ Type = 'StaticResource'; Member = $Matches[1]; RelativePath = $relativePath }
            break
        }
        "^$metadataRootPattern/staticresources/([^/]+)/" {
            $descriptor = [PSCustomObject]@{ Type = 'StaticResource'; Member = $Matches[1]; RelativePath = $relativePath }
            break
        }
        "^$metadataRootPattern/applications/([^/]+)\.app-meta\.xml$" {
            $descriptor = [PSCustomObject]@{ Type = 'CustomApplication'; Member = $Matches[1]; RelativePath = $relativePath }
            break
        }
        "^$metadataRootPattern/objects/([^/]+)/fields/([^/]+)\.field-meta\.xml$" {
            $descriptor = [PSCustomObject]@{ Type = 'CustomField'; Member = '{0}.{1}' -f $Matches[1], $Matches[2]; RelativePath = $relativePath }
            break
        }
        "^$metadataRootPattern/objects/([^/]+)/recordTypes/([^/]+)\.recordType-meta\.xml$" {
            $descriptor = [PSCustomObject]@{ Type = 'RecordType'; Member = '{0}.{1}' -f $Matches[1], $Matches[2]; RelativePath = $relativePath }
            break
        }
        "^$metadataRootPattern/objects/([^/]+)/validationRules/([^/]+)\.validationRule-meta\.xml$" {
            $descriptor = [PSCustomObject]@{ Type = 'ValidationRule'; Member = '{0}.{1}' -f $Matches[1], $Matches[2]; RelativePath = $relativePath }
            break
        }
        "^$metadataRootPattern/objects/([^/]+)/listViews/([^/]+)\.listView-meta\.xml$" {
            $descriptor = [PSCustomObject]@{ Type = 'ListView'; Member = '{0}.{1}' -f $Matches[1], $Matches[2]; RelativePath = $relativePath }
            break
        }
        "^$metadataRootPattern/objects/([^/]+)/compactLayouts/([^/]+)\.compactLayout-meta\.xml$" {
            $descriptor = [PSCustomObject]@{ Type = 'CompactLayout'; Member = '{0}.{1}' -f $Matches[1], $Matches[2]; RelativePath = $relativePath }
            break
        }
        "^$metadataRootPattern/objects/([^/]+)/businessProcesses/([^/]+)\.businessProcess-meta\.xml$" {
            $descriptor = [PSCustomObject]@{ Type = 'BusinessProcess'; Member = '{0}.{1}' -f $Matches[1], $Matches[2]; RelativePath = $relativePath }
            break
        }
        "^$metadataRootPattern/objects/([^/]+)/sharingReasons/([^/]+)\.sharingReason-meta\.xml$" {
            $descriptor = [PSCustomObject]@{ Type = 'SharingReason'; Member = '{0}.{1}' -f $Matches[1], $Matches[2]; RelativePath = $relativePath }
            break
        }
        "^$metadataRootPattern/objects/([^/]+)/webLinks/([^/]+)\.webLink-meta\.xml$" {
            $descriptor = [PSCustomObject]@{ Type = 'WebLink'; Member = '{0}.{1}' -f $Matches[1], $Matches[2]; RelativePath = $relativePath }
            break
        }
        "^$metadataRootPattern/objects/([^/]+)/([^/]+)\.object-meta\.xml$" {
            $descriptor = [PSCustomObject]@{ Type = 'CustomObject'; Member = $Matches[1]; RelativePath = $relativePath }
            break
        }
        "^$metadataRootPattern/labels/CustomLabels\.labels-meta\.xml$" {
            $descriptor = [PSCustomObject]@{ Type = 'CustomLabels'; Member = 'CustomLabels'; RelativePath = $relativePath }
            break
        }
    }

    if ($null -eq $descriptor) {
        return $null
    }

    [PSCustomObject]@{
        Type         = $descriptor.Type
        Member       = $descriptor.Member
        RelativePath = $descriptor.RelativePath
        Key          = '{0}|{1}' -f $descriptor.Type, $descriptor.Member
    }
}

function Get-ChangedMetadataDescriptor {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$BaseRef = 'HEAD~1',

        [Parameter()]
        [string]$HeadRef = 'HEAD',

        [Parameter()]
        [switch]$IncludeUntracked
    )

    $seenKeys = New-Object 'System.Collections.Generic.HashSet[string]'

    foreach ($entry in Get-GitDiffEntry -BaseRef $BaseRef -HeadRef $HeadRef -IncludeUntracked:$IncludeUntracked.IsPresent) {
        $descriptor = Get-SalesforceMetadataDescriptor -Path $entry.Path

        if ($null -eq $descriptor) {
            continue
        }

        $compositeKey = '{0}|{1}' -f $entry.Status, $descriptor.Key

        if (-not $seenKeys.Add($compositeKey)) {
            continue
        }

        [PSCustomObject]@{
            Status       = $entry.Status
            Type         = $descriptor.Type
            Member       = $descriptor.Member
            RelativePath = $descriptor.RelativePath
            PreviousPath = $entry.PreviousPath
        }
    }
}

function New-PackageXmlContent {
    param(
        [Parameter(Mandatory)]
        [object[]]$Metadata,

        [Parameter()]
        [string]$Version = (Get-DefaultPackageVersion)
    )

    $lines = New-Object 'System.Collections.Generic.List[string]'
    $lines.Add('<?xml version="1.0" encoding="UTF-8"?>')
    $lines.Add('<Package xmlns="http://soap.sforce.com/2006/04/metadata">')

    foreach ($group in $Metadata | Sort-Object Type, Member | Group-Object -Property Type) {
        $lines.Add('    <types>')

        foreach ($member in $group.Group.Member | Sort-Object -Unique) {
            $lines.Add("        <members>$member</members>")
        }

        $lines.Add("        <name>$($group.Name)</name>")
        $lines.Add('    </types>')
    }

    $lines.Add("    <version>$Version</version>")
    $lines.Add('</Package>')

    ($lines -join [System.Environment]::NewLine) + [System.Environment]::NewLine
}

Export-ModuleMember -Function Get-SalesforceCopilotConfiguration, Get-MetadataRootRelativePath, Get-MetadataRootRegex, Get-ManifestRelativePath, Get-ManifestDirectoryRelativePath, Get-SandboxConfigRootRelativePath, Get-WorkingRootRelativePath, Get-RepositoryRoot, Get-DefaultPackageVersion, Get-GitDiffEntry, Get-NormalizedRelativePath, Get-SalesforceMetadataDescriptor, Get-ChangedMetadataDescriptor, New-PackageXmlContent
