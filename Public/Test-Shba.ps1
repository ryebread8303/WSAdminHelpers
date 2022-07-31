<#
.SYNOPSIS
Check if a machine supports required security hardware to meet SHB-A standards.
.DESCRIPTION
To meet Secure Host Baseline - Army standards, a machine must:
* Have a TPM chip support spec version 2.0
* Use UEFI only, no legacy BIOS boot
* Have hardware virualization enabled.

In addition, we check for presence of a machine certificate because that's a requirement to authenticate with the network switches.
.PARAMETER ComputerName
Provide the name of the computer you would like to test.
.EXAMPLE
test-shba localhost


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
.EXAMPLE
("LOCALHOST","LEONW6SMAANB010","LEONW6SMAANB00A") | Test-SHBA


ComputerName        : LOCALHOST
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

ComputerName        : LEONW6SMAANB010
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

ComputerName        : LEONW6SMAANB00A
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
.NOTES
AUTHOR: O'Ryan Hedrick
COMPANY: Ft Leonard Wood Network Enterprise Center
LAST UPDATE: 23 MAR 2022
INTENDED AUDIENCE: Workstation admins
#>
function Test-SHBA {
    param(
        #Hostname of the computer you want to query
        [Alias("Name","CN")]
        [parameter(position=0,ValueFromPipeline=$true)]
        [string[]]
        $ComputerName = 'localhost'
    )
    begin{
        $output = @()
        #I'm creating this quick ping function because test-netconnection is slow.
        #It sends one ping using the ping dotnet class.
        function Test-QuickPing {
            param(
                [string]$HostName
            )
            $pinger = new-object system.net.networkinformation.ping
            $reply = $pinger.send($Hostname)
            If ($reply.Status -eq "Success"){$True}else{$false}
        }
    }
    process{
        #the process block uses a foreach block so that you can either pass an array of hostnames, or pipe them in
        foreach($name in $computername){
            #setup a CIM Session, I'm hoping reusing the same session will reduce query times
            $Dcom = New-CimSessionOption -Protocol Dcom
            $CimSession = New-CIMSession -ComputerName $Name -Name $Name -SessionOption $Dcom
            #skip the machine if it doesn't respond to ping
            if (!(test-quickping $name)){
                write-warning "$name does not respond to ping."
                continue #this means skip the rest of this iteration of the loop and continue to the next machine
            }
            #set the various properties to false by default, otherwise they come out blank if the features aren't configured
            $secureboot = $false
            $hardwarevirt = $false
            $CGConfigured = $false
            $CGRunning = $false
            $HVCIConfigured = $false
            $HVCIRunning = $false
            $VBSConfigured = $false
            $VBSRunning = $false
            #check for the TPM Spec Version
            $tpmspec = (Get-CIMInstance -namespace root\cimv2\security\microsofttpm -class win32_tpm  -cimsession $CIMSession | Select-Object specversion).specversion
            if($null -eq $tpmspec){$tpmspec = "Unknown"}
            #grab the device guard properties from WMI
            write-verbose "Collecting WMI data for computer $name"
            $securityproperties = Get-CIMInstance -ClassName win32_deviceguard -namespace root\Microsoft\windows\deviceguard -cimsession $CIMSession
            #if AvailableSecurityProperties contains 1, hardware virtualization is enabled.
            # if AvailableSecurityProperties contains 2, Secure Boot is enabled.
            switch ($securityproperties.AvailableSecurityProperties) {
                1 { $hardwarevirt = $true }
                2 { $secureboot = $true }
            }
            # code to check if CG and DG are running found at https://docs.microsoft.com/en-us/windows/security/identity-protection/credential-guard/credential-guard-manage
            switch ($securityproperties.securityservicesconfigured) {
                1 {$CGConfigured = $true}
                2 {$HVCIConfigured = $true}
            }
            switch ($securityproperties.securityservicesrunning) {
                1 {$CGRunning = $true}
                2 {$HVCIRunning = $true}
            }
            #check the status of virtualization based security
            switch ($securityproperties.virtualizationbasedsecuritystatus) {
                0 {$VBSConfigured = $false
                    $VBSRunning = $false}
                1 {$VBSConfigured = $true
                    $VBSRunning = $false}
                2 {$VBSConfigured = $true
                    $VBSRunning = $true}
            }
            #Add section to check for a device certificate, info on OneNote Remediation Issues page
            try{
                $certs = get-CIMInstance -class Army_Certificates -cimsession $CIMSession -erroraction "Stop"
                if($certs.Template -eq "USArmyComputerAuthenticationTemplate"){$certinstalled = $true}
            }catch{
                $certinstalled = $false
            }
            #create an output object
            $result = [pscustomobject]@{
                'ComputerName' = $Name;
                'TPMSpecVersion' = $tpmspec.split(",")[0];
                'SecureBootEnabled' = $secureboot;
                'HardwareVirtEnabled' = $hardwarevirt;
                'CGConfigured' = $CGConfigured;
                'CGRunning' = $CGRunning;
                'HVCIConfigured' = $HVCIConfigured
                'HVCIRunning' = $HVCIRunning;
                'VBSConfigured' = $VBSConfigured;
                'VBSRunning' = $VBSRunning
                'CertInstalled' = $certinstalled
            }
            #collect the results for this computer for eventual output
            Write-Verbose "Adding computer $name to output collection."
            $output += $result
            Remove-CIMSession $CIMSession
        }
    }
    end {
        #emit the output object
        #the reason for outputting an object is to make this more suitable
        #for use in other scripts.
        $output
    }
}