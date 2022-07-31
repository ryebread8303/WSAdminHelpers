<#
.SYNOPSIS
Fetch the last date a computer was imaged or IPU'd.
.DESCRIPTION
Function uses WMI to remotely query a computer for the InstallDate property of the Win32_OperatingSystem class. This date matches the last image or IPU date.

This is equivalent of WMIC OS get InstallDate, but using PowerShell and it fetches data from a remote computer.
.PARAMETER computername
Provide the name of the computer you want to check on.
.EXAMPLE
get-windowsinstalldate leonw6smaanb010

Thursday, August 26, 2021 12:40:31 PM
.NOTES
AUTHOR: O'Ryan Hedrick
COMPANY: Ft Leonard Wood Network Enterprise Center
LAST UPDATE: UNKNOWN
INTENDED AUDIENCE: Workstation administartors
#>
function Get-WindowsInstallDate {
    param(
        [Parameter(Mandatory=$true,Valuefrompipeline=$true)]
        [string]
        $computername
        )
    ([WMI]'').ConvertToDateTime((Get-WmiObject Win32_OperatingSystem -computername $computername).InstallDate)
}
