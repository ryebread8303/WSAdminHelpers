<#
.SYNOPSIS
Collect logs from a remote machine for troubleshooting.
.DESCRIPTION
This function collects logs from a remote machine, and copies them to a target destination. The files are named with the target's hostname, the type of log, and the time of collection. If the log is a directory of logs, that directory is zipped up when saved in the destination.
If you haven't logged into a computer before, te GPResult option will fail.
.PARAMETER ComputerName
The name of the computer you want logs from.
.PARAMETER DestinationPath
Specifiy the folder path you want to save the logs to.
.PARAMETER CertEnrollment
Use this switch to get certificate enrollment logs from Event Viewer.
.PARAMETER Sccm
Use this switch to collect the c:\windows\ccm\logs folder.
.PARAMETER GPResult
Use this switch to collect Group Policy information for this computer and user.
.NOTES
AUTHOR: O'Ryan R Hedrick
COMPANY: Ft Leonard Wood Network Enterprise Center
LAST UPDATE: 19 NOV 2021
INTENDED AUDIENCE: Workstation administrators
#>
function Get-LeonComputerLogs {
    param(
        [Parameter(mandatory=$true,ValueFromPipeLine=$true)]
        [string[]]
        $ComputerName,
        [string]
        $DestinationPath = "$env:Userprofile\Documents",
        [switch]
        $CertEnrollment,
        [switch]
        $Sccm,
        [switch]
        $GPResult
    )
    begin {
        Write-Verbose "Begin"
        #I'm using splatting to pass arguments to the compress-archive statements, so I start the hashtable here with the common argument
        $CompressArgs = @{
            CompressionLevel = 'Optimal'
        }
        #this function is used when I need a temporary place to store files, such as when copying SCCM logs over
        function New-TemporaryDirectory {
            $parent = [System.IO.Path]::GetTempPath()
            [string] $name = [System.Guid]::NewGuid()
            New-Item -ItemType Directory -Path (Join-Path $parent $name)
        }
    }
    process{
        Write-Verbose "Process"
        foreach ($Computer in $ComputerName){
            #this command requires the Test-PSRemoting module be installed. This allows use of my code for grabbing WinEvents
            Test-PSRemoting $Computer -fix
            #I'm using the timestamp in the destination file names
            $timestamp = get-date -format yyyyMMdd-HHmm
            #region get cert enrollment errors
            if ($CertEnrollment){
                #this query lets me specify which events I want to collect
                $xmlquery = @"
<QueryList>
  <Query Id="0" Path="Application">
    <Select Path="Application">*[System[Provider[@Name='Microsoft-Windows-CertificateServicesClient-AutoEnrollment' or @Name='Microsoft-Windows-CertificateServicesClient-CertEnroll'] and (Level=1  or Level=2 or Level=3)]]</Select>
  </Query>
</QueryList>
"@
                #I'm using PSRemoting because it's much tidier than trying PSExec
                invoke-command -computername $Computer -scriptblock {
                    get-winevent -filterxml $Using:xmlquery | select timecreated,machinename,logname,leveldisplayname,id,message | export-csv "c:\CertEnrollmentErrors.csv" -NoTypeInformation
                }
                copy-item "\\$Computer\c$\CertEnrollmentErrors.csv" "$DestinationPath\$Computer-Logs-CertEnrollment-$timestamp.csv"
            }
            #endregion
            #region zip up all the CCM logs
            if ($SCCM){
                #I can't create the archive directly from c:\windows\ccm\logs because compress-archive complains about the files being in use
                #so I have to copy the files to a temp dir first. Copy-Item doens't seem to care if something's touching the files.
                $TempDir = new-temporarydirectory
                Write-Verbose "Temp folder is $TempDir"
                copy-item \\$Computer\c$\windows\ccm\logs $TempDir -force -recurse
                $CompressArgs.Path = $TempDir
                $CompressArgs.DestinationPath = "$DestinationPath\$Computer-Logs-SCCM-$timestamp.zip"
                compress-archive @CompressArgs
                Remove-Item $TempDir -recurse
            }
            #endregion
            #region get gpresult
            if ($GPResult){
                Get-GPResultantSetOfPolicy -Computer $Computer -ReportType html -path "$DestinationPath\$Computer-Logs-GPResult-$timestamp.html"
            }
            #endregion get gpresult
        }#end loop through list of computers
    }
    end {
        Write-Verbose "End"
    }
}