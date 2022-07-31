<#
.SYNOPSIS
Remotely start a remote SCCM client repair.
.DESCRIPTION
Eddie Teague found this code in a V-Team chat. Package into ESDHelpers by O'Ryan.
.PARAMETER Computer
Provide the name of the computer that you want to start a SCCM client repair on.
.NOTES
AUTHOR: O'Ryan Hedrick, from code supplied by the V-Team.
COMPANY: Ft Leonard Wood Network Enterprise Center
LAST UPDATE: 22 MAR 2022
INTENDED AUDIENCE: Workstation admins.
#>
Function Repair-SCCMClient
{
    param(
        [Parameter(Mandatory=$true,valuefrompipeline=$true)]
        [String] $Computer
    )
$SMSCli = [wmiclass]"\\$Computer\root\ccm:sms_client"
$SMSCli.RepairClient()
}