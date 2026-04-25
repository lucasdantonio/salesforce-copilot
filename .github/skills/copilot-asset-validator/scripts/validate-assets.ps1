<#
.SYNOPSIS
Validates reusable GitHub Copilot assets in a repository.

.DESCRIPTION
Checks skills, agents, instructions, Markdown docs, and bundled PowerShell scripts
for frontmatter quality, required sections, broken relative links, weak discovery
descriptions, portability risks, and missing script help.

.PARAMETER RootPath
Repository root to validate.

.PARAMETER FailOnError
Returns a non-zero exit code when one or more error findings are reported.

.EXAMPLE
.\validate-assets.ps1 -RootPath .

.EXAMPLE
.\validate-assets.ps1 -RootPath . -FailOnError

.OUTPUTS
PSCustomObject findings followed by a summary line.
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string]$RootPath = '.',

    [Parameter()]
    [switch]$FailOnError
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$resolvedRoot = (Resolve-Path -Path $RootPath).Path
$findings = New-Object 'System.Collections.Generic.List[object]'

function Add-Finding {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Error', 'Warning')]
        [string]$Severity,

        [Parameter(Mandatory)]
        [string]$Rule,

        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter()]
        [int]$Line
    )

    $relativePath = [System.IO.Path]::GetRelativePath($resolvedRoot, $Path).Replace('\', '/')
    $lineValue = $null

    if ($PSBoundParameters.ContainsKey('Line') -and $Line -gt 0) {
        $lineValue = $Line
    }

    $findings.Add([PSCustomObject]@{
            Severity = $Severity
            Rule     = $Rule
            Path     = $relativePath
            Line     = $lineValue
            Message  = $Message
        })
}

function Get-FrontmatterInfo {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $content = Get-Content -Path $Path -Raw
    $match = [regex]::Match(
        $content,
        '\A---\r?\n(?<frontmatter>.*?)\r?\n---\r?\n?',
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )

    if (-not $match.Success) {
        return [PSCustomObject]@{
            Content        = $content
            HasFrontmatter = $false
            Values         = @{}
        }
    }

    $values = @{}

    foreach ($line in ($match.Groups['frontmatter'].Value -split '\r?\n')) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        if ($line -match '^\s*([A-Za-z0-9_-]+)\s*:\s*(.+?)\s*$') {
            $values[$Matches[1]] = $Matches[2].Trim()
        }
    }

    [PSCustomObject]@{
        Content        = $content
        HasFrontmatter = $true
        Values         = $values
    }
}

function Get-LineNumber {
    param(
        [Parameter(Mandatory)]
        [string]$Content,

        [Parameter(Mandatory)]
        [int]$Index
    )

    (($Content.Substring(0, $Index)) -split '\r?\n').Count
}

function Test-RequiredHeading {
    param(
        [Parameter(Mandatory)]
        [string]$Content,

        [Parameter(Mandatory)]
        [string]$Pattern,

        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Rule,

        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter()]
        [ValidateSet('Error', 'Warning')]
        [string]$Severity = 'Error'
    )

    if ($Content -notmatch $Pattern) {
        Add-Finding -Severity $Severity -Rule $Rule -Path $Path -Message $Message
    }
}

function Test-DescriptionQuality {
    param(
        [Parameter(Mandatory)]
        [string]$Description,

        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [ValidateSet('Skill', 'Agent', 'Instruction')]
        [string]$AssetType
    )

    $normalized = $Description.Trim().Trim('"', "'")

    if ($normalized.Length -lt 40) {
        Add-Finding -Severity 'Warning' -Rule 'WeakDescription' -Path $Path -Message "$AssetType description is short and may hurt discovery."
    }

    if ($AssetType -eq 'Skill' -and $normalized -notmatch '(?i)\buse when\b|\buse this skill\b|\buse when asked\b') {
        Add-Finding -Severity 'Warning' -Rule 'WeakDescription' -Path $Path -Message 'Skill description should explain when the skill should be loaded.'
    }
}

function Test-PortabilityPatterns {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Content
    )

    $codeBlockRanges = @([regex]::Matches($Content, '(?ms)^```.*?^```\s*$|^~~~.*?^~~~\s*$'))
    $checks = @(
        @{
            Rule    = 'RepoLocalReference'
            Pattern = '(?i)\blucasdantonio\b|\bsalesforce-copilot\b'
            Message = 'Contains a repo-local owner or repository reference.'
        },
        @{
            Rule    = 'RepoLocalReference'
            Pattern = '(?i)\bthis repo\b|\bthis repository\b'
            Message = 'Contains wording that may not stay portable when copied elsewhere.'
        },
        @{
            Rule    = 'EmailAddress'
            Pattern = '(?i)\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b'
            Message = 'Contains an email-like identifier that may be repo- or org-specific.'
        },
        @{
            Rule    = 'SalesforceOrgOrUserId'
            Pattern = '\b(?:00D|005)[A-Za-z0-9]{12}(?:[A-Za-z0-9]{3})?\b'
            Message = 'Contains a likely Salesforce org or user ID.'
        },
        @{
            Rule    = 'SalesforceDomain'
            Pattern = '(?i)\.my\.salesforce\.com\b'
            Message = 'Contains a Salesforce domain that may be environment-specific.'
        }
    )

    foreach ($check in $checks) {
        foreach ($match in [regex]::Matches($Content, $check.Pattern)) {
            $isInCodeBlock = $false

            foreach ($codeBlockRange in $codeBlockRanges) {
                if ($match.Index -ge $codeBlockRange.Index -and $match.Index -lt ($codeBlockRange.Index + $codeBlockRange.Length)) {
                    $isInCodeBlock = $true
                    break
                }
            }

            if ($isInCodeBlock) {
                continue
            }

            Add-Finding -Severity 'Warning' `
                -Rule $check.Rule `
                -Path $Path `
                -Line (Get-LineNumber -Content $Content -Index $match.Index) `
                -Message $check.Message
        }
    }
}

function Test-MarkdownLinks {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $content = Get-Content -Path $Path -Raw
    $directory = Split-Path -Path $Path -Parent
    $linkMatches = [regex]::Matches($content, '!?[[][^]]*[]][(](?<dest>[^)]+)[)]')

    foreach ($match in $linkMatches) {
        $destination = $match.Groups['dest'].Value.Trim()

        if ($destination -match '^\s*<(?<inner>[^>]+)>\s*$') {
            $destination = $Matches['inner']
        }

        if ($destination -match '^(?<path>\S+)\s+".*"$') {
            $destination = $Matches['path']
        }

        if ($destination -match '^(?i)(https?|mailto|tel|data):' -or $destination.StartsWith('#') -or $destination.StartsWith('/')) {
            continue
        }

        $targetPath = ($destination -split '[#?]', 2)[0]

        if ([string]::IsNullOrWhiteSpace($targetPath)) {
            continue
        }

        $combinedPath = Join-Path -Path $directory -ChildPath ([System.Uri]::UnescapeDataString($targetPath))

        if (-not (Test-Path -Path $combinedPath)) {
            Add-Finding -Severity 'Error' `
                -Rule 'BrokenRelativeLink' `
                -Path $Path `
                -Line (Get-LineNumber -Content $content -Index $match.Index) `
                -Message ("Relative link target not found: {0}" -f $destination)
        }
    }
}

function Test-PowerShellHelp {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $content = Get-Content -Path $Path -Raw

    if ($content -notmatch '(?s)\A<#[\s\S]*?\.SYNOPSIS[\s\S]*?\.DESCRIPTION[\s\S]*?\.EXAMPLE[\s\S]*?#>') {
        Add-Finding -Severity 'Error' -Rule 'MissingScriptHelp' -Path $Path -Message 'PowerShell script should include top-level comment-based help with SYNOPSIS, DESCRIPTION, and EXAMPLE sections.'
    }
}

$skillRoot = Join-Path -Path $resolvedRoot -ChildPath '.github/skills'

if (Test-Path -Path $skillRoot) {
    foreach ($skillDirectory in (Get-ChildItem -Path $skillRoot -Directory | Sort-Object Name)) {
        $skillFile = Join-Path -Path $skillDirectory.FullName -ChildPath 'SKILL.md'

        if (-not (Test-Path -Path $skillFile)) {
            Add-Finding -Severity 'Error' -Rule 'MissingSkillFile' -Path $skillDirectory.FullName -Message 'Skill directory is missing SKILL.md.'
            continue
        }

        $frontmatterInfo = Get-FrontmatterInfo -Path $skillFile
        $skillContent = $frontmatterInfo.Content

        if (-not $frontmatterInfo.HasFrontmatter) {
            Add-Finding -Severity 'Error' -Rule 'MissingFrontmatter' -Path $skillFile -Message 'SKILL.md is missing YAML frontmatter.'
        }

        foreach ($requiredField in @('name', 'description')) {
            if (-not $frontmatterInfo.Values.ContainsKey($requiredField)) {
                Add-Finding -Severity 'Error' -Rule 'MissingFrontmatterField' -Path $skillFile -Message ("SKILL.md is missing required frontmatter field '{0}'." -f $requiredField)
            }
        }

        if ($frontmatterInfo.Values.ContainsKey('name')) {
            $skillName = $frontmatterInfo.Values['name'].Trim('"', "'")

            if ($skillName -notmatch '^[a-z0-9][a-z0-9-]{0,63}$') {
                Add-Finding -Severity 'Error' -Rule 'InvalidSkillName' -Path $skillFile -Message 'Skill name should be lowercase, use hyphens, and stay within 64 characters.'
            }

            if ($skillName -ne $skillDirectory.Name) {
                Add-Finding -Severity 'Warning' -Rule 'SkillNameFolderMismatch' -Path $skillFile -Message 'Skill frontmatter name does not match the skill folder name.'
            }
        }

        if ($frontmatterInfo.Values.ContainsKey('description')) {
            Test-DescriptionQuality -Description $frontmatterInfo.Values['description'] -Path $skillFile -AssetType 'Skill'
        }

        Test-RequiredHeading -Content $skillContent -Pattern '(?m)^#\s+.+' -Path $skillFile -Rule 'MissingHeading' -Message 'SKILL.md should include one H1 title.'
        Test-RequiredHeading -Content $skillContent -Pattern '(?m)^##\s+When to Use This Skill\s*$' -Path $skillFile -Rule 'MissingSection' -Message 'SKILL.md should include a When to Use This Skill section.'

        if (Test-Path -Path (Join-Path -Path $skillDirectory.FullName -ChildPath 'scripts')) {
            Test-RequiredHeading -Content $skillContent -Pattern '(?m)^##\s+Scripts\s*$' -Path $skillFile -Rule 'MissingSection' -Message 'Script-backed skills should include a Scripts section.'
        }

        Test-RequiredHeading -Content $skillContent -Pattern '(?m)^##\s+Gotchas\s*$' -Path $skillFile -Rule 'MissingSection' -Message 'Skills should include a Gotchas section for non-obvious constraints.' -Severity 'Warning'
        Test-PortabilityPatterns -Path $skillFile -Content $skillContent
    }
}

$agentRoot = Join-Path -Path $resolvedRoot -ChildPath '.github/agents'

if (Test-Path -Path $agentRoot) {
    foreach ($agentFile in (Get-ChildItem -Path $agentRoot -Filter '*.agent.md' -File | Sort-Object Name)) {
        $frontmatterInfo = Get-FrontmatterInfo -Path $agentFile.FullName
        $content = $frontmatterInfo.Content

        if (-not $frontmatterInfo.HasFrontmatter) {
            Add-Finding -Severity 'Error' -Rule 'MissingFrontmatter' -Path $agentFile.FullName -Message 'Agent file is missing YAML frontmatter.'
        }

        if (-not $frontmatterInfo.Values.ContainsKey('description')) {
            Add-Finding -Severity 'Error' -Rule 'MissingFrontmatterField' -Path $agentFile.FullName -Message 'Agent file is missing required frontmatter field ''description''.'
        } else {
            Test-DescriptionQuality -Description $frontmatterInfo.Values['description'] -Path $agentFile.FullName -AssetType 'Agent'
        }

        if (-not $frontmatterInfo.Values.ContainsKey('name')) {
            Add-Finding -Severity 'Warning' -Rule 'MissingFrontmatterField' -Path $agentFile.FullName -Message 'Agent file should include a name field for discoverability.'
        }

        Test-RequiredHeading -Content $content -Pattern '(?m)^#\s+.+' -Path $agentFile.FullName -Rule 'MissingHeading' -Message 'Agent file should include one H1 title.'
        Test-RequiredHeading -Content $content -Pattern '(?m)^##\s+When to Use This Agent\s*$' -Path $agentFile.FullName -Rule 'MissingSection' -Message 'Agent file should include a When to Use This Agent section.'
        Test-RequiredHeading -Content $content -Pattern '(?m)^##\s+Responsibilities\s*$' -Path $agentFile.FullName -Rule 'MissingSection' -Message 'Agent file should include a Responsibilities section.'
        Test-RequiredHeading -Content $content -Pattern '(?m)^##\s+Workflow\s*$' -Path $agentFile.FullName -Rule 'MissingSection' -Message 'Agent file should include a Workflow section.'
        Test-RequiredHeading -Content $content -Pattern '(?m)^##\s+Guardrails\s*$' -Path $agentFile.FullName -Rule 'MissingSection' -Message 'Agent file should include a Guardrails section.'
        Test-PortabilityPatterns -Path $agentFile.FullName -Content $content
    }
}

$instructionRoot = Join-Path -Path $resolvedRoot -ChildPath '.github/instructions'

if (Test-Path -Path $instructionRoot) {
    foreach ($instructionFile in (Get-ChildItem -Path $instructionRoot -Filter '*.instructions.md' -File | Sort-Object Name)) {
        $frontmatterInfo = Get-FrontmatterInfo -Path $instructionFile.FullName
        $content = $frontmatterInfo.Content

        if (-not $frontmatterInfo.HasFrontmatter) {
            Add-Finding -Severity 'Error' -Rule 'MissingFrontmatter' -Path $instructionFile.FullName -Message 'Instruction file is missing YAML frontmatter.'
        }

        foreach ($requiredField in @('description', 'applyTo')) {
            if (-not $frontmatterInfo.Values.ContainsKey($requiredField)) {
                Add-Finding -Severity 'Error' -Rule 'MissingFrontmatterField' -Path $instructionFile.FullName -Message ("Instruction file is missing required frontmatter field '{0}'." -f $requiredField)
            }
        }

        if ($frontmatterInfo.Values.ContainsKey('description')) {
            Test-DescriptionQuality -Description $frontmatterInfo.Values['description'] -Path $instructionFile.FullName -AssetType 'Instruction'
        }

        Test-RequiredHeading -Content $content -Pattern '(?m)^#\s+.+' -Path $instructionFile.FullName -Rule 'MissingHeading' -Message 'Instruction file should include one H1 title.'
        Test-RequiredHeading -Content $content -Pattern '(?m)^##\s+.+' -Path $instructionFile.FullName -Rule 'MissingSection' -Message 'Instruction file should include at least one H2 section.'
        Test-PortabilityPatterns -Path $instructionFile.FullName -Content $content
    }
}

foreach ($markdownFile in (Get-ChildItem -Path $resolvedRoot -Filter '*.md' -Recurse -File | Sort-Object FullName)) {
    Test-MarkdownLinks -Path $markdownFile.FullName
}

foreach ($powerShellScript in (Get-ChildItem -Path $resolvedRoot -Filter '*.ps1' -Recurse -File | Sort-Object FullName)) {
    Test-PowerShellHelp -Path $powerShellScript.FullName
}

$sortedFindings = @($findings |
        Sort-Object Severity, Rule, Path, Line)

if ($sortedFindings.Count -eq 0) {
    Write-Output 'Asset validation passed with no findings.'
    return
}

$sortedFindings

$errorCount = @($sortedFindings | Where-Object { $_.Severity -eq 'Error' }).Count
$warningCount = @($sortedFindings | Where-Object { $_.Severity -eq 'Warning' }).Count

Write-Output ("Asset validation found {0} error(s) and {1} warning(s)." -f $errorCount, $warningCount)

if ($FailOnError.IsPresent -and $errorCount -gt 0) {
    exit 1
}
