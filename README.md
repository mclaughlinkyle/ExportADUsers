# ExportADUsers
 PowerShell script to export Active Directory users from Windows Server

### Parameters:
`-ServerDomain`: The domain of the Windows Server.<br>
`-OrganizationUnit`: The organization unit to export accounts from.<br>
`-OnlyActiveUsers`: Only include accounts that are enabled and have a last logon within 180 days ago.<br>
`-SearchSubOrgUnits`: Search not only the passed organization unit but also any nested units within it.<br>
`-LogVerbosity`: Level of information about user accounts to be included in the exported CSV file.<br>
&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;(read more in the documentation of the script)

### Example usage:
```
Export-ADUsersCSV -ServerDomain 'com.org.local' -OrganizationUnit 'Managers' -OnlyActiveUsers -SearchSubOrgUnits -LogVerbosity 'Normal'
```

This will export users from the domain `com.org.local` and in the organizational unit `Managers` on the Windows Server you execute this script on.
