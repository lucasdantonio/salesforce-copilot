<#
.SYNOPSIS
Assigns permission sets after a sandbox refresh from JSON config.

.DESCRIPTION
Reads assignments from config/sandbox/permset-assignments.json and generates
anonymous Apex to insert missing PermissionSetAssignment records.

.EXAMPLE
.\assign-permsets.ps1 -TargetOrg my-sandbox
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$TargetOrg,

    [Parameter()]
    [string]$ConfigPath = 'config\sandbox\permset-assignments.json',

    [Parameter()]
    [switch]$DryRun
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..\scripts\salesforce\SalesforceCopilotUtils.psm1') -Force

function ConvertTo-ApexString {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Value
    )

    "'" + $Value.Replace('\', '\\').Replace("'", "\'") + "'"
}

$repositoryRoot = Get-RepositoryRoot
$configFullPath = Join-Path -Path $repositoryRoot -ChildPath $ConfigPath

if (-not (Test-Path -Path $configFullPath)) {
    Write-Warning ("Config file not found: {0}" -f $configFullPath)
    return
}

$assignments = @((Get-Content -Path $configFullPath -Raw | ConvertFrom-Json))

if ($assignments.Count -eq 0) {
    Write-Output 'No permission set assignments were defined.'
    return
}

$usernames = $assignments | ForEach-Object { ConvertTo-ApexString -Value $_.Username }
$permsetNames = $assignments | ForEach-Object { @($_.PermissionSets) } | ForEach-Object { $_ } | ForEach-Object { ConvertTo-ApexString -Value $_ } | Sort-Object -Unique
$apexLines = New-Object 'System.Collections.Generic.List[string]'

$apexLines.Add(("Map<String, Id> userIdsByUsername = new Map<String, Id>(); for (User row : [SELECT Id, Username FROM User WHERE Username IN ({0})]) userIdsByUsername.put(row.Username, row.Id);" -f ($usernames -join ', ')))
$apexLines.Add(("Map<String, Id> permsetIdsByName = new Map<String, Id>(); for (PermissionSet row : [SELECT Id, Name FROM PermissionSet WHERE Name IN ({0})]) permsetIdsByName.put(row.Name, row.Id);" -f ($permsetNames -join ', ')))
$apexLines.Add('List<PermissionSetAssignment> assignmentsToInsert = new List<PermissionSetAssignment>();')

foreach ($assignment in $assignments) {
    foreach ($permsetName in @($assignment.PermissionSets)) {
        $username = ConvertTo-ApexString -Value $assignment.Username
        $permset = ConvertTo-ApexString -Value $permsetName
        $apexLines.Add(("if (userIdsByUsername.containsKey({0}) && permsetIdsByName.containsKey({1})) {{ Integer assignmentCount = [SELECT Count() FROM PermissionSetAssignment WHERE AssigneeId = :userIdsByUsername.get({0}) AND PermissionSetId = :permsetIdsByName.get({1})]; if (assignmentCount == 0) assignmentsToInsert.add(new PermissionSetAssignment(AssigneeId = userIdsByUsername.get({0}), PermissionSetId = permsetIdsByName.get({1}))); }}" -f $username, $permset))
    }
}

$apexLines.Add('if (!assignmentsToInsert.isEmpty()) insert assignmentsToInsert;')

$tempApexPath = Join-Path -Path $repositoryRoot -ChildPath '.sf\sandbox\assign-permsets.apex'
$tempDirectory = Split-Path -Path $tempApexPath -Parent

if (-not (Test-Path -Path $tempDirectory)) {
    New-Item -Path $tempDirectory -ItemType Directory -Force | Out-Null
}

Set-Content -Path $tempApexPath -Value ($apexLines -join [System.Environment]::NewLine) -Encoding UTF8
Write-Output ("Generated Apex script at {0}" -f $tempApexPath)

if (-not $DryRun.IsPresent) {
    & sf apex run --target-org $TargetOrg --file $tempApexPath
}
