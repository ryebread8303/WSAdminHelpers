#I created my own ping cmdlet because Test-NetConnection was a little slow
function Test-QuickPing {
    param(
        [string]$HostName
    )
    $pinger = new-object system.net.networkinformation.ping
    $reply = $pinger.send($Hostname)
    If ($reply.Status -eq "Success"){$True}else{$false}
}
