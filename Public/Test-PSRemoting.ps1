<#
.SYNOPSIS
Check if WinRM is enabled on the target, and optionally enable it.
.DESCRIPTION
Without the -fix parameter, the script pings the WinRM TCP port to determine if WinRM is enabled. If the -fix parameter is supplied, the script will use a remote WMI call to attempt enabling WinRM.
.PARAMETER ComputerName
Provide the name of the computer you are testing.
.PARAMETER Fix
Use this switch if you would like to turn on PSRemoting.
.EXAMPLE
test-psremoting leonw6smaanb010
True
.NOTES
AUTHOR: O'Ryan R Hedrick
COMPANY: Ft Leonard Wood Network Enterprise Center
LAST UPDATE: 16 MAR 2022
INTENDED AUDIENCE: Workstation admins.
#>
function Test-PSRemoting {
    [cmdletbinding()]
    param(
        [string]$ComputerName,
        #Fix will attempt using PSExec to run the PowerShell command to enable PSRemoting
        [switch]$Fix
    )
    #test-netconnection can test tcp ports, so we have it check the WinRM port and return whether that's open
    if(!(Test-QuickPing $ComputerName)){
        Write-Error "Computer $ComputerName is offline."
    }
    if(!(test-netconnection $ComputerName -commontcpport WinRM -informationlevel quiet)){
        Write-Log -Console -Severity Warning -Message "$ComputerName does not respond to WinRM."
        if ($Fix) {
            #if PSRemoting is not enabled, we use WMI to run the Enable-PSRemoting PowerShell command.
            #This replaces using PSExec to run the command.
            invoke-wmimethod -class win32_process -name create -argumentlist 'powershell.exe -command "enable-psremoting -skipnetworkprofilecheck"' -computername $ComputerName | out-null
            Start-Sleep 10
            Test-PSRemoting -ComputerName $ComputerName
        } else {
            $false
        }
    } else {
        $true
    }
}