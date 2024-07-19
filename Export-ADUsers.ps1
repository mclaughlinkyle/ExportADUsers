
<##
 ##  Author: Kyle McLaughlin
 ##
 ##  Wrote this script to export data for user accounts from our Active Directory.
 ##     Exports the data as a CSV file, for easy use in spreadsheet editors or for other data processing.
 ##
 ##  Written on PowerShell Version 4
##>

# Import the AD module
Import-Module ActiveDirectory  

<#
    Export active desired users including all properties

    $OrgUnit                 - Export users from this organization unit
    $FilterOnlyActiveUsers   - If $true: only include 'Enabled' accounts, and accounts with a last logon less than 180 days ago
#>
Function ExportOUUsers([String]$OrgUnit, [Boolean]$FilterOnlyActiveUsers)
{
    # Base search filter, for domain and org unit
    [String]$SearchBaseFilter = "OU=$OrgUnit,DC=com,DC=org,DC=local"

    [Int]$DaysInactive = 180
    [DateTime]$Time = (Get-Date).AddDays(-($DaysInactive))  

    # Used to check if user account is not disabled and if their last logon was no more than 180 days ago
    $ActiveUserFilter = { LastLogonTimeStamp -GT $Time -and Enabled -EQ $True }

    # Create sub dir for specified org unit, removes whitespace from OrgUnit
    [String]$OUExportsDir = "$PSScriptRoot\Exports\$($OrgUnit -Replace '\s', '')"

    # If our dir doesnt exist, create it
    If (-Not(Test-Path -Path $OUExportsDir))
    { 
        MkDir $OUExportsDir
        #Write "Created directory '$OUExportsDir'."
    }

    # Date variable used in CSV file name
    $FormattedDate = Get-Date -f yyyyMMddhhmm
    $IncludedUsers = "$(If($FilterOnlyActiveUsers){'Active'}Else{'All'})Users"
    $CSVFile = "$OUExportsDir\$IncludedUsers-$FormattedDate.csv"
    
    # Get the users from AD and export as CSV
    Get-ADUser -SearchBase $SearchBaseFilter -Filter $(If ($FilterOnlyActiveUsers) { $ActiveUserFilter } Else { '*' }) -Properties * |
        Select-Object Name, SAMAccountName, Description, LastLogonDate |
        Sort-Object 'Created' |
        Export-CSV -Path $CSVFile -Encoding UTF8 -NoTypeInformation
}

<#
    - Account properties:
        Enabled, LockedOut, MemberOf, ObjectCategory, ObjectClass, ObjectGUID, objectSid, HomeDirectory, HomeDrive, ScriptPath

    - Name / descriptor properties: 
        CN, CanonicalName, UserPrincipalName, SAMAccountName, DistinguishedName, Name, DisplayName, GivenName, Initials, OtherName, Description, Title

    - Password / logon properties:
        PasswordExpired, PasswordNeverExpires, PasswordNotRequired, CannotChangePassword, lastLogoff, lastLogon, LastLogonDate, lastLogonTimestamp

#>
