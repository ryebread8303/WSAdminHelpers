enum LogLevel {
    Verbose
    Info
    Warning
    Error
    Critical
}
<#
.SYNOPSIS
Helper function handles needed logging capability in scripts.
.DESCRIPTION
This function relies on an enum to be added to your script. Paste the following block 
into your script to add the needed enum:

enum LogLevel {
    Verbose
    Info
    Warning
    Error
    Critical
}

If you want to log INFO or VERBOSE entries, you'll need to set a $LogLevel variable 
to the appropriate level.
.NOTES
AUTHOR: O'Ryan R Hedrick
COMPANY: Ft Leonard Wood Network Enterprise Center
LAST UPDATE: 3 FEB 2022
INTENDED AUDIENCE: Script writers
TODO:
* Log to an arbitray text file
* Log to event viewer - NEEDS TESTING
* Test with the ParameterSets added
#>
function Write-Log {
    [CmdletBinding(DefaultParameterSetName="Console")]
    param(
        [Parameter(Mandatory=$true,Position=1)]
        [string]
        $Message,
        [Parameter(Mandatory=$true,Position=0)]
        [ValidateSet("Info","Warning","Error","Critical","Verbose")]
        [string]
        $Severity,
        <#[ValidateSet("Temp","Console","EventLog")]
        [string]
        $Target,#>
        [Parameter(ParameterSetName="Console")]
        [Parameter(ParameterSetName="WinEvent")]
        [Parameter(ParameterSetName="Temp")]
        [switch]
        $Console,
        [Parameter(Mandatory=$true,ParameterSetName="Temp")]
        [Parameter(ParameterSetName="WinEvent")]
        [Parameter(ParameterSetName="Console")]
        [switch]
        $Temp,
        #Used to put a log entry into the Windows EventLog
        [Parameter(ParameterSetName='WinEvent',Mandatory=$true)]
        [ValidateSet("Application","System")]
        [string]
        $WinLogName,
        #Used to put a log entry into the Windows EventLog.
        [Parameter(ParameterSetName='WinEvent',Mandatory=$true)]
        [string]
        $WinLogSource,
        [Parameter(ParameterSetName='WinEvent',Mandatory=$true)]
        [int16]
        $WinLogCategory,
        [Parameter(ParameterSetName='WinEvent',Mandatory=$true)]
        [int]
        $WinLogEventID

    )
    $Target = @()
    if($Temp){$Target += 'Temp'}
    if($Console){$Target += 'Console'}
    $DateTimeStamp = get-date -format yyyyMMdd:HHmmZz
    $DateStamp = get-date -format yyyyMMdd
    $Severity = $Severity.toUpper()
    #If the calling script has not set a $LogLevel variable, assume it should be set to Warning
    if ($null -eq $LogLevel){$LogLevel = "Warning"}
    if ([LogLevel]$Severity -lt [LogLevel]$LogLevel) {
        Write-Debug "LogLevel is $LogLevel, Severity is $Severity"
        return
        }
    $ErrorColors = @{
        BackgroundColor = "Black"
        ForeGroundColor = "Red"
    }
    $WarningColors = @{
        BackgroundColor = "Black"
        ForeGroundColor = "Yellow"
    }
    switch ($Target) {
        'Temp' {
            #We get the name of the script that called Write-Log, and append it to LEONPSLogger to get our log filename
            Write-Debug $MyInvocation.ScriptName
            $Caller = split-path $MyInvocation.ScriptName -leaf
            try {
                $PriorErrorActionPreference = $ErrorActionPreference
                $ErrorActionPreference = "Stop"
                $Caller = [System.Io.Path]::GetFileNameWithoutExtension($Caller)
                $ErrorActionPreference = $PriorErrorActionPreference
            } catch {
                Write-Debug "$caller"
            }
            #If write-log is called directly from an interactive prompt, replace the $Caller variable with 
            # something that doesn't have invalid filename characters
            If ($Caller -eq "<scriptblock>"){$Caller = "LEONPSLogger"}else{$Caller = "LEONPSLogger_$Caller"}
            $LogFilePath = "$env:temp\$Caller-$DateStamp.txt"
            Write-Debug "Log File should be at $LogFilePath"
            if (-not (test-path $LogFilePath)){
                New-item -path $LogFilePath -ItemType File | out-null
            }
            Add-Content -path $LogFilePath -Value "$Severity : $DateTimeStamp : $Message"
        }
        'Console' {
            $string = "$Severity : $DateTimeStamp : $Message"
            switch ($Severity) {
                'Critical' {Write-Host $string @ErrorColors}
                'Error' {Write-Host $string @ErrorColors}
                'Warning' {Write-Host $string @WarningColors}
                'Info' {Write-Host $string}
                'Verbose' {Write-Host $string}
            }
        }
        'EventLog' {
            #Win events don't map to the same severities this function uses, 
            # so we need to map our severities to the ones that are used in 
            # the event log.
            switch ($Severity){
                'Critical' {$Severity = "Error"}
                'Info' {$Severity = 'Informaiton'}
                'Verbose' {$Severity = 'Information'}
            }
            Write-EventLog -LogName $WinLogName -Source $WinLogSource -Category $WinLogCategory -EventID $WinLogEventID -EntryType $Severity
        }
    }
}
