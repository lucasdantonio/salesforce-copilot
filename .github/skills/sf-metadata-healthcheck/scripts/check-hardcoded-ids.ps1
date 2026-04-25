<#
.SYNOPSIS
Finds likely hardcoded Salesforce record IDs.

.DESCRIPTION
Searches source files for 15- or 18-character Salesforce-style IDs and reports
their file location for review.

.EXAMPLE
.\check-hardcoded-ids.ps1
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string]$RootPath = '.',

    [Parameter()]
    [switch]$FailOnMatch
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$pattern = '\b[a-zA-Z0-9]{15}(?:[a-zA-Z0-9]{3})?\b'
$include = @('*.cls', '*.trigger', '*.js', '*.html', '*.page', '*.component', '*.xml')
$files = Get-ChildItem -Path $RootPath -Recurse -File -Include $include |
    Where-Object { $_.FullName -notmatch '\\(node_modules|\.git)\\' }

$findings = @(foreach ($file in $files) {
    Select-String -Path $file.FullName -Pattern $pattern -AllMatches | ForEach-Object {
        foreach ($match in $_.Matches) {
            [PSCustomObject]@{
                Path  = $_.Path
                Line  = $_.LineNumber
                Match = $match.Value
            }
        }
    }
})

if ($findings.Count -eq 0) {
    Write-Output 'No likely hardcoded Salesforce IDs were found.'
    return
}

Write-Warning ("Found {0} likely hardcoded Salesforce ID value(s)." -f $findings.Count)
$findings | Sort-Object Path, Line -Unique

if ($FailOnMatch.IsPresent) {
    exit 1
}
