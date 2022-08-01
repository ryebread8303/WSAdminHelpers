# WSAdminHelpers

This module is written for Windows workstation administrators to ease some common tasks. Some of these tools may require your environment to be configured in a particular way, so you may need to modify some tools. As I created more documentation for this module I'll call these tools out.

# Key Tools

## Get-WorkstationStatus
This tool checks a variety of settings and gathers information from a remote Windows machine. This includes gathering some identifying information, such as a MAC address and the machines serial number, checking security posture, and verifying a few things that should be configured after imaging a machine.

Machine identity information:

* Manufacturer
* Model
* Serial Number
* MAC Address

Security posture

* TPM spec version
* SecureBoot and UEFI status
* Hardware virtualization status
* BitLocker status
* Credential Guard Status
* Hardware Virtualized Code Integrity status

Image verification

* Universal Build Revision
* Windows install date
* Detected video cards
* McAfee Agent service status
* A list of drivers disabled or in error status
* Windows version or build number.

The cmdlet can take an array of hostnames as input and will query each hostname and display the results. If the -passthru argument is provided, it will emit an array of objects containing the query results. This can be piped into something like Export-CSV to generate a report.

The cmdlet is currently oriented towards a specific environment, and still needs to be generalized for public use.

## Get-LoggedInUser

This command accepts a hostname, and returns the username of the remote machine's currently logged in user. If no user is logged in the result will be blank.

## Test-PSRemoting

This command accepts a hostname, and tests if the port used by WinRM is open. If you supply the -fix argument, and the port isn't open, the script will attempt to run the PowerShell command `Enable-PSRemoting`.

## Repair-SCCMClient

This command attempts to remotely start a repair action for the SCCM client.

## Get-BDEObjects

This command fetches BitLocker recovery passwords from AD. You can give it the computername, or the recovery key ID.

## Get-ComputerLogs

This command can remotely fetch SCCM and certificate enrollment logs, as well as attempting to get the Group Policy RSoP data.