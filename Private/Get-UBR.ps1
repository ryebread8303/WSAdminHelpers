#this is a helper function to get the patch level of the target machine
#The UBR number changes with the cumulative patch installs
function Get-UBR {
    param (
        $ComputerName = ""
    )
    $Hive = "LocalMachine"
    $KeyPath = "SOFTWARE\Microsoft\Windows NT\CurrentVersion"
    $Value = "UBR"
    $RegistryKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($Hive,$ComputerName)
    $SubKey = $RegistryKey.OpenSubKey($KeyPath)
    $Value = $SubKey.GetValue($Value)
    $Value
}
