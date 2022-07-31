<#
These enums are for interpreting the values returned by WMI calls later in the script.
#>
enum BDEStatus {
    Protection_Off
    Protection_On
    Protection_Unknown
}
enum DGSecurityProperties {
    No_Relavant_Props
    Hardware_Virt
    SecureBoot
    DMA_Protection
    Secure_Memory_Overwrite
    NX_Protections
    SMM_Mitigations
    Mode_Based_Execution_Control
}

<#
.SYNOPSIS
Check a workstations current status.
.DESCRIPTION
This function Uses Test-SHBA to check the status of SHB-A mandated configuration items, and then adds a few more checks and displays the results to the console.

Anything that comes up a yellow warning should be manually verified.
.PARAMETER ComputerName
Provide the name of the computer you are checking.
.PARAMETER Passthru
Use this switch to output an object containing the computer status instead of printing results to console. This is for passing the output to another script, or piping the results to Export-CSV.
.EXAMPLE
get-workstationstatus
Querying localhost
Manufacturer: Dell Inc.
Model: Latitude 5580
Serial Number: XXXXXXXX
MAC XX:XX:XX:XX:XX:XX
Universal Build Revision (Patch level): 1645
Windows Install Date: 8/24/2021 4:36:05 PM
SecureBoot and UEFI enabled.
Hardware Virtualization is enabled.
TPM Version is:  2.0
Windows Version 20H2
Bitlocker Status is:  Protection_On
Credential Guard is running.
HVCI is running.
Detected video card  NVIDIA GeForce 930MX
Detected video card  Intel(R) HD Graphics 620
McAfee is running.
A machine certificate is installed.
WARNING: Make sure drivers for the following devices are good:
 Microsoft Visual Studio Location Simulator Sensor

Run the command without any arguments to check your own machine.
.EXAMPLE
get-workstationstatus leonw6smaanb010
Querying leonw6smaanb010
Manufacturer: Dell Inc.
Model: Latitude 5580
Serial Number: GZVHWD2
MAC A4:4C:C8:36:8A:AB
Universal Build Revision (Patch level): 1645
Windows Install Date: 8/26/2021 12:40:31 PM
SecureBoot and UEFI enabled.
Hardware Virtualization is enabled.
TPM Version is:  2.0
Windows Version 20H2
Bitlocker Status is:  Protection_On
Credential Guard is running.
HVCI is running.
Detected video card  Intel(R) HD Graphics 620
McAfee is running.
A machine certificate is installed.
WARNING: Make sure drivers for the following devices are good:
 Cisco AnyConnect Secure Mobility Client Virtual Miniport Adapter for Windows x64

Run the command with a computer name to remotely check a machine.
.EXAMPLE
get-workstationstatus -passthru | export-csv c:\temp\wsStatus.csv -notypeinformation
Querying localhost
PS C:\> import-csv c:\temp\wsStatus.csv


ComputerName        : localhost
TPMSpecVersion      : 2.0
SecureBootEnabled   : True
HardwareVirtEnabled : True
CGConfigured        : True
CGRunning           : True
HVCIConfigured      : True
HVCIRunning         : True
VBSConfigured       : True
VBSRunning          : True
CertInstalled       : True
SerialNumber        : C2WHWD2
TPMOwned            : True
Manufacturer        : Dell Inc.
WindowsBuild        : 19042
UBR                 : 1645
VideoAdapters       : System.Object[]
MAC                 : System.Object[]
BadDrivers          : Microsoft Visual Studio Location Simulator Sensor
Model               : Latitude 5580
EncryptionStatus    : Protection_On
McAfeeStatus        : Running
InstallDate         : 8/24/2021 4:36:05 PM

The first command runs Get-WorkstationStatus and exports the result to a csv file. The second command uses Import-CSV to show the contents of that file.
.EXAMPLE
("localhost","leonw6smaanb010") | get-workstationstatus -passthru | export-csv c:\temp\wsStatus.csv -notypeinformation
Querying localhost
Querying leonw6smaanb010
PS C:\> import-csv c:\temp\wsStatus.csv | ft

ComputerName    TPMSpecVersion SecureBootEnabled HardwareVirtEnabled CGConfigured CGRunning HVCIConfigured HVCIRunning
------------    -------------- ----------------- ------------------- ------------ --------- -------------- -----------
localhost       2.0            True              True                True         True      True           True
leonw6smaanb010 2.0            True              True                True         True      True           True

The first command pipes multiple computernames to Get-WorkstationStatus and exports the results of all queries to a CSV file. The second command lists the contents of the file, showing that both machines have their information listed. You would probably use Excel to view the contents of this file.
.NOTES
AUTHOR: O'Ryan Hedrick
COMPANY: Ft Leonard Wood Network Enterprise Center
LAST UPDATE: 23 MAR 2022
INTENDED AUDIENCE: Workstation Admins
#>
function Get-WorkstationStatus {
    [CmdletBinding()]
    [Alias("gws")]
    param (
        [alias('cn')]
        [Parameter(ValueFromPipeline=$true)]
        [string[]]
        $ComputerName = "localhost",
        [switch]
        $Passthru
    )
    # using a process block so that you can pipe a list of computer names to the function
    process {
        #I use this foreach to allow the user to pass an array of computernames, instead of having to pass names one at a time
        foreach($Computer in $ComputerName) {
            #setup a CIM Session, I'm hoping reusing the same session will reduce query times
            $Dcom = New-CimSessionOption -Protocol Dcom
            $CimSession = New-CIMSession -ComputerName $Computer -Name $Computer -SessionOption $Dcom
            #write a message to the console so the user knows we're querying a machine now
            Write-Host "Querying $Computer"
            #ping the computer, if it doesn't respond skip to the next computer
            if(-not (test-quickping $Computer)){
                Write-Warning "Computer is offline"
                continue
            }
            #try a query to verify the RPC service is available, skip this machine if it isn't.
            try{
                Get-CIMInstance -cimsession $CIMSession -class win32_bios -property serialnumber -erroraction "Stop" | 
                Select-Object serialnumber | out-null
            }
            catch{
                write-warning "Unable to query machine."
                continue
            }
            #region gather information about the computer using WMI
            #win32_networkadapterconfiguration contains NIC information
            #win32_operatingsystem contains OS build
            #win32_computersystem give use the make and model of the physical computer
            #win32_bios contains our serialnumber. It also has the BIOS version number, if we want to add that in here later
            #win32_encryptablevolume give us info on the BitLocker protected volumes
            #win32_pnpentity gets info from things that show up in Device Manager. We're checking for devices that aren't ok.
            #win32_videocontroller gets info for graphics cards. We want to be sure we don't have a Microsoft Basic Display.
            #Win32_Tpm gets TPM data. We grab the IsOwned property because sometimes machines aren't setting BDE because TPM isn't owned.
            $ComputerStatus = Test-SHBA $Computer
            $MAC = Get-CIMInstance win32_networkadapterconfiguration -cimsession $CIMSession | Where-Object {$_.ipenabled -eq $true} | Select-Object -ExpandProperty macaddress
            $WindowsBuild = (Get-CIMInstance win32_operatingsystem -property buildnumber -cimsession $CIMSession).buildnumber
            $MakeAndModel = (Get-CIMInstance -query "SELECT manufacturer,model FROM win32_computersystem" -cimsession $CIMSession)
            $SerialNumber = (Get-CIMInstance -CIMSession $CIMSession -class win32_bios | Select-Object serialnumber).serialnumber
            #The [BDEStatus] is the enum declared at the top of the script. It converts the number returned by WMI into a string that can be interpreted by a tech
            $EncryptionStatus = [BDEStatus](Get-CIMInstance -namespace root\cimv2\security\microsoftvolumeencryption -class win32_encryptablevolume -cimsession $CIMSession | 
                select-object ProtectionStatus).ProtectionStatus
            $BadDrivers = (Get-CIMInstance -class win32_pnpentity -property name,status -cimsession $CIMSession | 
                where-object {$_.status -ne "OK"} | 
                select-object name,status).name
            $VideoAdapters = (Get-CIMInstance -class win32_videocontroller -property name -cimsession $CIMSession).name
            $TPMOwned = (Get-CIMInstance -class Win32_Tpm -Namespace root\cimv2\Security\MicrosoftTpm -property IsOwned_InitialValue -cimsession $CIMSession).IsOwned_InitialValue
            #from what I can tell, the service named masvc is the main agent for McAfee. I'm assuming that if it's running, the machine is either good, or the machine will check in and Jorge will find out it's not good and fix it.
            $McAfeeStatus = (Get-Service -Name masvc -computername $Computer).status
            #UBR is a patch level, it tells you which cumulative update was last applied
            $UBR = get-ubr $Computer
            #Install is set for images and IPU. good to check for determining if a machine was recently imaged.
            $InstallDate = Get-WindowsInstallDate $Computer
            #Adding the data we just found to the results of Test-SHBA
            $ComputerStatus | Add-Member -notepropertymembers @{
                MAC = $MAC;
                WindowsBuild = $WindowsBuild;
                Manufacturer = $MakeAndModel.Manufacturer;
                Model = $MakeAndModel.Model;
                SerialNumber = $SerialNumber;
                EncryptionStatus = $EncryptionStatus;
                BadDrivers = $BadDrivers;
                VideoAdapters = $VideoAdapters;
                TPMOwned = $TPMOwned;
                McAfeeStatus = $McAfeeStatus;
                UBR = $UBR;
                InstallDate = $InstallDate
            }
            #endregion
            #If -Passthru is set, the user wants the pipe the results to something else, like Export-CSV, so we will simply emit the object we just created
            if($Passthru){
                $ComputerStatus
            } else { #if -Passthru isn't set, the user wants the report written to the console

                #region output results
                <#
                I'm using switch statements instead of if statements because I like the way they look.
                This section is just for providing output to the user, letting them know at a glance
                what should be examined more verse what is ok.
                #>
                "Manufacturer: {0}" -f $ComputerStatus.Manufacturer
                "Model: {0}" -f $ComputerStatus.Model
                "Serial Number: {0}" -f $ComputerStatus.SerialNumber
                "MAC {0}" -f $ComputerStatus.MAC
                "Universal Build Revision (Patch level): {0}" -f $ComputerStatus.UBR
                "Windows Install Date: {0}" -f $ComputerStatus.InstallDate
                switch ($ComputerStatus.SecureBootEnabled) {
                    $true {Write-Host -object "SecureBoot and UEFI enabled." -foregroundcolor 'green'}
                    $false {Write-Warning "Secure Boot is not Enabled."}
                    default {Write-Warning "Check UEFI and SecureBoot status."}
                }
                switch ($ComputerStatus.hardwarevirtenabled){
                    $true {Write-Host "Hardware Virtualization is enabled." -foregroundcolor 'green'}
                    default {Write-Warning "Enable hardware virtualization."}
                }
                switch ($ComputerStatus.TPMSpecVersion){
                    '2.0' {Write-Host "TPM Version is: "$ComputerStatus.TPMSpecVersion -foregroundcolor 'green'}
                    default {Write-Warning "TPM Version is: $($ComputerStatus.TPMSpecVersion)"}
                }
                switch ($ComputerStatus.TPMOwned){
                    $false {Write-Warning "TPM is not owned."}
                    $true {<# Write-Host "TPM is owned" -foregroundcolor 'green' #>}
                }
                switch ($ComputerStatus.WindowsBuild) {
                    '17763' {Write-Warning "Windows Version: 1809"}
                    '18363' {Write-Warning "Windows Version: 1909"}
                    '19042' {Write-Host "Windows Version 20H2"-foregroundcolor 'green'}
                    default {Write-Warning "Windows Build is: $($ComputerStatus.WindowsBuild)"}
                }
                switch ($ComputerStatus.EncryptionStatus) {
                    "Protection_On" {Write-Host "Bitlocker Status is: " $ComputerStatus.EncryptionStatus -foregroundcolor 'green'}
                    default {Write-Warning "Bitlocker Status is: $($ComputerStatus.EncryptionStatus)"}
                }
                switch ($ComputerStatus.CGRunning){
                    $true {Write-Host "Credential Guard is running." -ForegroundColor 'green'}
                    $false {Write-Warning "Check Credential Guard."}
                }
                switch ($ComputerStatus.HVCIRunning){
                    $true {Write-Host "HVCI is running." -ForegroundColor 'green'}
                    $false {Write-Warning "HVCI is not running."}
                }
                switch ($ComputerStatus.VideoAdapters){
                    'Microsoft Basic Display Adapter' {Write-Warning "Microsoft Basic Display Adapter found"}
                    $null {Write-Warning "No display adapter found."}
                    default {Write-Host "Detected video card "$_ -ForegroundColor 'green'}
                }
                switch ($ComputerStatus.McAfeeStatus) {
                    'Running' {Write-Host "McAfee is running." -foregroundcolor 'green'}
                    default {Write-Warning "Check McAfee."}
                }
                switch ($ComputerStatus.CertInstalled){
                    $true {Write-Host "A machine certificate is installed." -foregroundcolor 'green'}
                    default {Write-Warning "Request a machine certificate."}
                }
                if (-not (Get-CIMInstance army_certificates).Template){Write-Warning "Check Army_Certificates WMI class."}
                switch ($null -ne $ComputerStatus.BadDrivers) {
                    $true {Write-Warning "Make sure drivers for the following devices are good: `n`t$($ComputerStatus.BadDrivers)"}
                    default {Write-Host "Drivers are good." -foregroundcolor 'green'}
                }
            }
        #endregion
        Remove-CIMSession $CIMSession
        }
    }
}

