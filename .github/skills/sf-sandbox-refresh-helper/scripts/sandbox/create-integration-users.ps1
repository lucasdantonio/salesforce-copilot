<#
.SYNOPSIS
Creates or updates integration users in a sandbox from JSON config.

.DESCRIPTION
Reads user definitions from the configured sandbox root, generates
anonymous Apex, and upserts the users by Username.

.EXAMPLE
.\create-integration-users.ps1 -TargetOrg my-sandbox
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$TargetOrg,

    [Parameter()]
    [string]$ConfigPath,

    [Parameter()]
    [switch]$DryRun
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..\scripts\salesforce\SalesforceCopilotUtils.psm1') -Force

if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
    $ConfigPath = Join-Path -Path (Get-SandboxConfigRootRelativePath) -ChildPath 'integration-users.json'
}

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

$users = @((Get-Content -Path $configFullPath -Raw | ConvertFrom-Json))

if ($users.Count -eq 0) {
    Write-Output 'No integration users were defined.'
    return
}

$usernames = $users | ForEach-Object { ConvertTo-ApexString -Value $_.Username }
$profileNames = $users | ForEach-Object { ConvertTo-ApexString -Value $_.ProfileName } | Sort-Object -Unique
$apexLines = New-Object 'System.Collections.Generic.List[string]'

$apexLines.Add('Map<String, Id> profileByName = new Map<String, Id>();')
$apexLines.Add(("for (Profile row : [SELECT Id, Name FROM Profile WHERE Name IN ({0})]) profileByName.put(row.Name, row.Id);" -f ($profileNames -join ', ')))
$apexLines.Add(("Set<String> usernames = new Set<String>{ {0} };" -f ($usernames -join ', ')))
$apexLines.Add('Map<String, User> existingUsers = new Map<String, User>();')
$apexLines.Add('for (User row : [SELECT Id, Username FROM User WHERE Username IN :usernames]) existingUsers.put(row.Username, row);')
$apexLines.Add('List<User> usersToInsert = new List<User>();')
$apexLines.Add('List<User> usersToUpdate = new List<User>();')

foreach ($user in $users) {
    $username = ConvertTo-ApexString -Value $user.Username
    $email = ConvertTo-ApexString -Value $user.Email
    $lastName = ConvertTo-ApexString -Value $user.LastName
    $alias = ConvertTo-ApexString -Value $user.Alias
    $profileName = ConvertTo-ApexString -Value $user.ProfileName
    $timeZone = ConvertTo-ApexString -Value ($(if ($user.TimeZoneSidKey) { $user.TimeZoneSidKey } else { 'America/Sao_Paulo' }))
    $locale = ConvertTo-ApexString -Value ($(if ($user.LocaleSidKey) { $user.LocaleSidKey } else { 'en_US' }))
    $encoding = ConvertTo-ApexString -Value ($(if ($user.EmailEncodingKey) { $user.EmailEncodingKey } else { 'UTF-8' }))
    $language = ConvertTo-ApexString -Value ($(if ($user.LanguageLocaleKey) { $user.LanguageLocaleKey } else { 'en_US' }))

    $apexLines.Add(("if (existingUsers.containsKey({0})) {{ User currentUser = existingUsers.get({0}); currentUser.Email = {1}; currentUser.LastName = {2}; currentUser.Alias = {3}; usersToUpdate.add(currentUser); }} else {{ usersToInsert.add(new User(Username = {0}, Email = {1}, LastName = {2}, Alias = {3}, ProfileId = profileByName.get({4}), TimeZoneSidKey = {5}, LocaleSidKey = {6}, EmailEncodingKey = {7}, LanguageLocaleKey = {8})); }}" -f $username, $email, $lastName, $alias, $profileName, $timeZone, $locale, $encoding, $language))
}

$apexLines.Add('if (!usersToInsert.isEmpty()) insert usersToInsert;')
$apexLines.Add('if (!usersToUpdate.isEmpty()) update usersToUpdate;')

$tempApexPath = Join-Path -Path $repositoryRoot -ChildPath (Join-Path -Path (Get-WorkingRootRelativePath) -ChildPath 'create-integration-users.apex')
$tempDirectory = Split-Path -Path $tempApexPath -Parent

if (-not (Test-Path -Path $tempDirectory)) {
    New-Item -Path $tempDirectory -ItemType Directory -Force | Out-Null
}

Set-Content -Path $tempApexPath -Value ($apexLines -join [System.Environment]::NewLine) -Encoding UTF8
Write-Output ("Generated Apex script at {0}" -f $tempApexPath)

if (-not $DryRun.IsPresent) {
    & sf apex run --target-org $TargetOrg --file $tempApexPath
}
