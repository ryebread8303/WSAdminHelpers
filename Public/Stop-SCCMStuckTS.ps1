<#
.SYNOPSIS
Clear task sequences that are stuck on a remote computer.
.DESCRIPTION
Sometimes a task sequence has an error that doesn't stop the task sequence, so it sits in the installing state indefinitely. Use this function to clear out such task sequences.
.NOTES
AUTHOR: O'Ryan Hedrick
COMPANY: Ft Leonard Wood Network Enterprise Center
LAST UPDATE: UNKNOWN
INTENDED AUDIENCE: Workstation admins
#>
function Stop-SCCMStuckTS {
    param(
        [Parameter(mandatory=$true)]
        [string]
        $ComputerName = $env:ComputerName
    )
    $TSExecutionRequests= Get-WMIObject -ComputerName $ComputerName -Namespace root\ccm\SoftMgmtAgent -Class CCM_TSExecutionRequest -Filter "State = 'Completed' And CompletionState = 'Failure'"
    if ($TSExecutionRequests) {
        $TSExecutionRequests.Delete()
        Get-Service ccmexec -ComputerName $ComputerName | Restart-Service
    }
}