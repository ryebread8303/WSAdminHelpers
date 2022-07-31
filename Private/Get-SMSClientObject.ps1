<#
.SYNOPSIS
This command creates a SMS_Client object.
.DESCRIPTION
Use the object to force hardware inventory or start a client repair.
.NOTES
AUTHOR: O'Ryan R Hedrick
COMPANY: Ft Leonard Wood Network Enterprise Center
LAST UPDATE: 16 MAR 2022
INTENDED AUDIENCE: Workstation Admins
#>
function Get-SMSClientObject {
    param(
        [parameter(mandatory=$true)]
        [string]$ComputerName
    )
    [wmiclass]"\\$ComputerName\root\ccm:sms_client"
}