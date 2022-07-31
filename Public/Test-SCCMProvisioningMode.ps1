<#
.SYNOPSIS
Remotely check a registry to find if SCCM client provisioning mode is set.
.DESCRIPTION
This script should be tested more, but we haven't had machines sitting around with provisioning mode set.
.NOTES
AUTHOR: O'Ryan Hedrick
COMPANY: Ft Leonard Wood Network Enterprise Center
LAST UPDATE: UNKNOWN
INTENDED AUDIENCE: Workstation administrators
#>
function Test-SCCMProvisioningMode {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $ComputerName
    )
    Write-Log -Console -Severity Warning -Message "This command is not well tested due to a lack of available test subjects."
    # These variable declarations are going to be fed into a method to remotely fetch the value of a registry key
    $Hive = "LocalMachine"
    $KeyPath = "SOFTWARE\Microsoft\CCM\MmcExec"
    $Value = "ProvisioningMode"
    #There wasn't a good PoSH cmdlet for remotely fetching registry keys, so I'm using
    #a .NET object to handle that
    $RegistryKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($Hive,$ComputerName)
    $SubKey = $RegistryKey.OpenSubKey($KeyPath)
    try {
        $Value = $SubKey.GetValue($Value)
    } catch [System.Management.Automation.RuntimeException] {} catch {$PSItem} 
    #this function returns a boolean value, true if provisioning mode is set
    #false if provisioning mode is not set
    $Value -eq "True"
}