<#
.SYNOPSIS
Show the currently logged in user of an online computer.
.DESCRIPTION
Query WMI on the target machine to obtain the username property from the win32_computersystem class.
.PARAMETER computername
Provide the name of the computer you want to query.
.EXAMPLE
get-loggedinuser leonw6smaanb010

username
--------
NANW\joshua.a.curtis4
.NOTES
AUTHOR: O'Ryan R Hedrick
COMPANY: Ft Leonard Wood Network Enterprise Center
LAST UPDATE: 10 NOV 2021
INTENDED AUDIENCE: Workstation administrators
#>
function Get-LoggedInUser {
    [Alias('guser')]
    param([Parameter(Mandatory=$true)][string]$computername)
    Get-WMIobject -class win32_computersystem -computername $computername -property username | select-object username
    }