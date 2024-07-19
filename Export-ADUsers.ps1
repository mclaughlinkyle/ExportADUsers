
<##
 ##  Author: Kyle McLaughlin
 ##
 ##  Export data for user accounts from Active Directory.
 ##     Exports the data as a CSV file, for easy use in spreadsheet editors or for other data processing.
 ##
 ##  Written on PowerShell Version 4
##>

# Import the AD module
Import-Module ActiveDirectory

<#
    .SYNOPSIS
    Build string of properties to select from ADUser object when exporting.

    .PARAMS
    $PropertiesSelection can be: ALL, VERBOSE, NORMAL, MINIMAL,
                                 or you can enter specific properties comma separated (Example: 'CanonicalName, Name, LastLogonDate')
#>
function Get-PropertiesString([string]$PropertiesSelection)
{
    switch ($PropertiesSelection)
    {
        'ALL' { '*' }
        'VERBOSE' { 'Created', 'ObjectClass', 'ObjectGUID', 'objectSid', 'MemberOf', 'CanonicalName', 'SAMAccountName', 'Name', 'DisplayName', 'GivenName', 'Initials', 'OtherName', 'Description', 'Title', 'Enabled', 'LockedOut', 'HomeDirectory', 'HomeDrive', 'ScriptPath', 'PasswordExpired', 'PasswordNeverExpires', 'PasswordNotRequired', 'CannotChangePassword', 'lastLogoff', 'lastLogon', 'LastLogonDate', 'lastLogonTimestamp'; break }
        'NORMAL' { 'Created', 'SAMAccountName', 'Name', 'DisplayName', 'Description', 'LastLogonDate' }
        'MINIMAL' { 'SAMAccountName', 'Name', 'LastLogonDate' }
        default { 
            # Split custom properties into array
            $PropertiesSelection = $PropertiesSelection.Replace('\s', '')
            return $PropertiesSelection.Split(',')
        }
    }
}

<#
    .SYNOPSIS
    Export users with properties from Active Directory as a CSV file.

    .PARAMS
    $ServerDomain                  - Domain of the organization (Ex: 'com.org.local')

    $OrganizationUnit              - Export users from this organization unit

    $SearchSubOrgUnits             - If present: include users from an other org units nested within $OrganizationUnit

    $OnlyActiveUsers               - If present: only include 'Enabled' accounts, and accounts with a last logon less than 180 days ago

    $LogVerbosity                  - Verbosity of the exported CSV file. (how many properties are included)
                                      See Get-PropertiesString function
#>
function Export-ADUsersCSV([string]$ServerDomain, [string]$OrganizationUnit, [switch]$OnlyActiveUsers, [switch]$SearchSubOrgUnits, [string]$LogVerbosity)
{
    # Format DC text for SearchBaseFilter
    $domainArr = $ServerDomain.Split('.')
    [string]$domainFormatted = ""
    foreach ($substr in $domainArr)
    {
        $domainFormatted += "DC=$substr,"
    }

    # Only remove extra comma from above foreach loop if the domain was delimited. 
    # (Example: If domain was 'com.org.local' and not just 'org')
    if ($domainArr.Length -gt 0) 
    {
        $domainFormatted = $domainFormatted.Substring(0, $domainFormatted.Length - 1)
    }
    
    # Base search filter, for domain and org unit
    [string]$searchBaseFilter = "OU=$OrganizationUnit,$domainFormatted"

    $pastDateTime = (Get-Date).AddDays(-180)  

    # Used to check if user account is not disabled and if their last logon was no more than 180 days ago
    $activeUserFilter = { LastLogonTimeStamp -gt $pastDateTime -and Enabled -eq $true }

    # Create sub dir for specified org unit, removes whitespace from OrgUnit
    [string]$exportDir = "$PSScriptRoot\Exports\$($OrganizationUnit -Replace '\s', '')"

    # If our dir doesnt exist, create it
    if (-not(Test-Path -Path $exportDir))
    { 
        MkDir $exportDir
    }

    # Date variable used in CSV file name
    $formattedDate = Get-Date -f yyyyMMddhhmm
    $logVer = "Log$LogVerbosity"
    $includedUsers = "$(if ($OnlyActiveUsers.IsPresent) {'Active'} else {'All'})Users"
    $fileCSV = "$exportDir\$logVer-$includedUsers-$formattedDate.csv"
    
    # The properties to select out of each ADUser object
    $exportProperties = $(Get-PropertiesString -PropertiesSelection $LogVerbosity)

    # Scope for the search
    $scope = $(if ($SearchSubOrgUnits.IsPresent) { 'Subtree' } else { 'OneLevel' })

    # Filter for the search
    $filter = $(if ($OnlyActiveUsers.IsPresent) { $activeUserFilter } else { '*' })

    # Get the users from AD and export as CSV
    Get-ADUser -SearchBase $searchBaseFilter -SearchScope $scope -Filter $filter -Properties * |
        Select-Object $exportProperties |
        Sort-Object 'Created' |
        Export-CSV -Path $fileCSV -Encoding UTF8 -NoTypeInformation
}

<#
    Example usage (include or exclude these switches -OnlyActiveUsers -SearchSubOrgUnits based on your desired export)
     
    This will export users from the domain com.org.local on the windows server machine you execute this script on.
    It will export active users (enabled accounts & last logon within 180 days ago) from the Managers organization unit 
    and all organization units nested under Managers, while including a normal amount of information about each user
#>   
Export-ADUsersCSV -ServerDomain 'com.org.local' -OrganizationUnit 'Managers' -OnlyActiveUsers -SearchSubOrgUnits -LogVerbosity 'Normal'
