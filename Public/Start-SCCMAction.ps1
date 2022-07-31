<#
.SYNOPSIS
Start SCCM client actions on remote clients.
.DESCRIPTION
Use this to kick off policy updates and hardware inventories remotely, withing having to log into the computer.
.NOTES
AUTHOR: O'Ryan Hedrick
COMPANY: Ft Leonard Wood Network Enterprise Center
LAST UPDATE: UNKNOWN
INTENDED AUDIENCE: Workstation administrators
#>
Function Start-SCCMAction {
    param(
        #GUID for the SCCM action you want to trigger.
        [Parameter(ParameterSetName='UserDefined',Mandatory=$true)]
        [string]
        $Action,
        #The name to the computer you want to trigger the action on. Defaults to localhost.
        [Parameter(Position=0)]
        [string]
        $ComputerName="localhost",
        #Switch sets the action to Machine Policy Retrieval & Evaluation Cycle
        [Parameter(ParameterSetName='MachinePolicy',Mandatory=$true)]
        [switch]
        $MachinePolicy,
        #Switch sets the action to Machine Policy Retrieval & Evaluation Cycle
        [Parameter(ParameterSetName='ApplicationManagerPolicy',Mandatory=$true)]
        [switch]
        $ApplicationManagerPolicy,
        #Switch sets the action to Machine Policy Retrieval & Evaluation Cycle
        [Parameter(ParameterSetName='HardwareInventory',Mandatory=$true)]
        [switch]
        $HardwareInventory
    )
    If($MachinePolicy){$Action = "{00000000-0000-0000-0000-000000000021}"}
    If($ApplicationManagerPolicy){$Action = "{00000000-0000-0000-0000-000000000121}"}
    If($HardwareInventory){$Action = '{00000000-0000-0000-0000-000000000001}'}
    Invoke-WmiMethod -Namespace root\ccm -Class sms_client -ComputerName $ComputerName -Name TriggerSchedule $Action
}