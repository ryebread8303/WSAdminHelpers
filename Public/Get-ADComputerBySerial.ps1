<#
.SYNOPSIS
Fetch a computer's AD account given its service tag.
.DESCRIPTION
This script is a wrapper for the Get-ADComputer function. It fills in the search base for you to you don't need to explicitly limit the search to Ft Leonard Wood, and handles formating the filter argument to search the info property.

.NOTES
AUTHOR: O'Ryan Hedrick
COMPANY: Ft Leonard Wood Network Enterprise Center
LAST UPDATE: UNKNOWN
INTENDED AUDIENCE: Workstation admins
#>
function Get-ADComputerBySerial {
	[cmdletbinding()]
	param(
		# Computer serial number to search AD for.
		[Parameter(ValueFromPipeline=$true,Mandatory=$true)]
		[string]
		$SerialNumber,
		[Parameter(Mandatory=$true)]
		[string]
		$SearchBase
	)
	#the info property contains the serial number of the computer that goes with that AD account
	get-ADComputer -SearchBase $SearchBase -filter "info -like '*$SerialNumber*'"
}