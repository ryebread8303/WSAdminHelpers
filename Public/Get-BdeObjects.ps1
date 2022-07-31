<#
.SYNOPSIS
Fetch BitLocker recovery passwords.
.DESCRIPTION
The Bitlocker recovery passwords are stored in AD as child objects of the computer account. This script fetches those records.
.PARAMETER ComputerName
This is the name of the computer you want to find a recovery password for.
.PARAMETER KeyID
This is the 8 character key id presented by the BitLocker recovery screen.
.EXAMPLE
get-bdeobjects -computername LEONW6SMAANB008

Name                                                            msFVE-RecoveryPassword
----                                                            ----------------------
2021-08-24T11:42:52-06:00{XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX} XXXXXX-XXXXXX-XXXXXX-XXXXXX-XXXXXX-XXXXXX-XXXXXX-XXXXXX
2019-11-13T09:16:12-06:00{XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX} XXXXXX-XXXXXX-XXXXXX-XXXXXX-XXXXXX-XXXXXX-XXXXXX-XXXXXX

This example fetches the recovery passwords from the computername. The passwords and recovery keyIDs have been redacted.
.EXAMPLE
get-bdeobjects -computername LEONW6SMAANB008 | fl


Name                   : 2021-08-24T11:42:52-06:00{XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX}
msFVE-RecoveryPassword : XXXXXX-XXXXXX-XXXXXX-XXXXXX-XXXXXX-XXXXXX-XXXXXX-XXXXXX
DistinguishedName      : CN=2021-08-24T11:42:52-06:00{XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX},CN=LEONW6SMAANB008,OU=Test,
                         DC=foo,DC=com

Name                   : 2019-11-13T09:16:12-06:00{XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX}
msFVE-RecoveryPassword : XXXXXX-XXXXXX-XXXXXX-XXXXXX-XXXXXX-XXXXXX-XXXXXX-XXXXXX
DistinguishedName      : CN=2019-11-13T09:16:12-06:00{XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX},CN=LEONW6SMAANB008,OU=OU=Test,
                         DC=foo,DC=com

This example fetches the recovery information by computername, but then pipes the result to Format-List to present the data differently. The passwords and recovery keyIDs have been redacted.
.EXAMPLE 
get-bdeobjects -keyid XXXXXXXX

Name                                                            msFVE-RecoveryPassword
----                                                            ----------------------
2021-08-24T11:42:52-06:00{XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX} XXXXXX-XXXXXX-XXXXXX-XXXXXX-XXXXXX-XXXXXX-XXXXXX-XXXXXX
This example fetches the recovery information by the key ID. The passwords and recovery keyIDs have been redacted.
.NOTES
AUTHOR: 
COMPANY: Ft Leonard Wood Network Enterprise Center
LAST UPDATE: 
INTENDED AUDIENCE: 
#>
function Get-BDEObjects {
	[cmdletbinding()]
	param (
		[Parameter(mandatory=$true,ParameterSetName="ComputerName")]
		[string]$computername,
		[Parameter(mandatory=$true,ParameterSetName="KeyID")]
		[string]$KeyID,
		[Parameter(mandatory=$true)]
		[string]$SearchBase
	)
	if($ComputerName){
		$computerado = Get-ADComputer $computername
		#BDE recovery passwords are stored in child objects of the computer with that volume.
		#the Get-ADObject commands search for those child objects and returns them.
		$BitLockerObjects = Get-ADObject -Filter {objectclass -eq 'msFVE-RecoveryInformation'} -SearchBase $computerado.DistinguishedName -Properties 'msFVE-RecoveryPassword'
	} elseif ($KeyID) {
		$BitLockerObjects = get-ADObject -Filter "objectclass -eq 'msFVE-RecoveryInformation' -and Name -like '*{*$KeyID*}'" -SearchBase $SearchBase -Properties 'msFVE-RecoveryPassword'
	}
		$BitLockerObjects | select-object Name,msFVE-RecoveryPassword,DistinguishedName
}