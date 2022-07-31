$here = $PSScriptRoot
$parent = split-path $here -parent

. $parent\Private\Write-Log.ps1
. $parent\Private\Test-QuickPing.ps1
. $parent\Public\Test-PSRemoting.ps1

Describe "Unit Tests:Test-PSRemoting" {
    Context "Pinging" {
        Mock "Write-Log"
        Mock "Invoke-WMIMethod"
        Mock "Test-QuickPing"
        Mock "Test-QuickPing" {$false} -ParameterFilter {$ComputerName -eq 'badmachine'}
        Mock "Test-QuickPing" {$true} -ParameterFilter {$ComputerName -eq 'goodmachine'}
        Mock "Test-QuickPing" {$true} -ParameterFilter {$ComputerName -eq 'PSRemotingOn'}
        Mock "Test-QuickPing" {$true} -ParameterFilter {$ComputerName -eq 'PSRemotingOff'}
        Mock "Test-NetConnection" {$false} -ParameterFilter {$ComputerName -eq 'PSRemotingOff'}
        Mock "Test-NetConnection" {$true} -ParameterFilter {$ComputerName -eq 'PSRemotingOn'}
        It "Should throw an exception if the target doesn't respond to ping" {
            {Test-PSRemoting badmachine} | Should Throw
        }
        It "Should not throw an exception if the target responds to ping" {
            {Test-PSRemoting goodmachine} | Should Not Throw
        }
        It "Should not try invoking WMI if test-netconnection returns true and the -fix parameter was provided." {
            Test-PSRemoting -fix PSRemotingOn
            Assert-MockCalled "Invoke-WMIMethod" -Times 0
        }
        It "Should try invoking WMI if test-netconnection returns false and the -fix parameter was provided." {
            Test-PSRemoting -fix PSRemotingOff
            Assert-MockCalled "Invoke-WMIMethod" -Times 1
        }
    }
}