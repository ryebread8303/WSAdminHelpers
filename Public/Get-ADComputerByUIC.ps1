<#
.SYNOPSIS
Fetch all hostnames in AD for site LEON and a given UIC.
.DESCRIPTION
This script wraps the Get-ADComputer command for convenience. It buils a filter for computer names starting with LEON and the UIC provided as a parameter and returns the accounts.
.NOTES
AUTHOR: O'Ryan Hedrick
COMPANY: Ft Leonard Wood Network Enterprise Center
LAST UPDATE: 12 MAY 2022
INTENDED AUDIENCE: Workstation administrators
#>
function Get-ADComputerbyUIC {
    [cmdletbinding()]
    param(
        [Parameter(mandatory=$true)]
        [string]$UIC
    )
    $filter = "(name=leon" + $UIC + "*)"
    get-adcomputer -ldapfilter $filter
} # end function
    