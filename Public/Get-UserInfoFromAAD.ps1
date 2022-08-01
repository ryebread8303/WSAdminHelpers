<#
.SYNOPSIS
Retrieve user data from US Government Azure AD
.DESCRIPTION
This script uses the AzureAD PowerShell module to query AzureAD for user information. User UIC is stored in the user's extension properties.

The first time you run this command in a session, you will be prompted for your army.mil credentials. Subsequent runs within that same session won't need credentials; you're connection stays open until you close your PowerShell session.
.PARAMETER UserPrincipal
Provide the user's army.mil email address, or as much of the beginning of it as you can.
.PARAMETER EmployeeID
Provide the EmployeeID number of the user.
.EXAMPLE
gufaad -userprincipal foo.b.baz


UserName        : foo.b.baz.civ@example.com
DisplayName     : Baz, Foo B
EmployeeID      : XXXXXXXXXXXXXXXX
UIC             : XXXXXX
AttachedUIC     : XXXXXX
TelephoneNumber : (XXX) XXX-XXXX
Email           : XXX.X.XXX.XXX@example.com
City            : FoggyCity
CompanyName     : Widgets R Us
Unit            : 
.NOTES
AUTHOR: O'Ryan R Hedrick
COMPANY: Ft Leonard Wood Network Enterprise Center
LAST UPDATE: 2 FEB 2022
INTENDED AUDIENCE: Workstation administrators
#>
function Get-UserInfoFromAAD {
    [CmdletBinding()]
    [Alias("gufaad")]
    param(
        [Parameter(ParameterSetName="principal")]
        [string]
        $UserPrincipal,
        [Parameter(ParameterSetName="EmployeeID")]
        [string]
        $EmployeeID,
        [Parameter()]
        [string]
        $AzureEnvironment
    )
    #Check if we're already connected to AzureAD, and connect if we haven't already
    try {
    Get-AzureADTenantDetail | Out-Null
    } catch {
        connect-azuread -AzureEnvironmentName $AzureEnvironment | Out-Null
    }
    #region search by user principal
    if ($UserPrincipal){
        $Users = Get-AzureADUser -filter "startswith(UserPrincipalName,'$UserPrincipal')"
    }
    #endregion search by user principal
    #region search by EmployeeID
    if ($EmployeeID){
        $Users = Get-AzureADUser -filter "startswith(employeeid,'$EmployeeID')"
    }
    #endregion search by EmployeeID
    #region emit results
    If ($null -eq $users){
        Write-Error "No user found"
    } else {
        foreach($User in $Users) {
            [pscustomobject]@{
                UserName = $User.UserPrincipalName
                DisplayName = $User.DisplayName
                EmployeeID = $User.extensionproperty.employeeId
                UIC = $User.extensionproperty.extension_d6e3e32847d649e78bcbdbd1fab0bba9_dodUIC
                AttachedUIC = $User.extensionproperty.extension_d6e3e32847d649e78bcbdbd1fab0bba9_dodAttachedUIC
                TelephoneNumber = $User.TelephoneNumber
                Email = $User.mail
                City = $User.City
                CompanyName = $User.CompanyName
                Unit = $User.Department
            }
        }
    }
    #endregion emit results
}