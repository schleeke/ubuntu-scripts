<#
#>
PARAM ()

function Script:Get-Session() {
    [string[]] $output = & openvpn3 sessions-list;
    [bool] $started = $false;
    $retVal = [PSCustomObject]@{
        Name = ''
        Path = ''
        Owner = ''
        Session = ''
        Status = '' };
    foreach ($line in $output) {
        [string] $line = $line.Trim();
        if ($line -eq 'No sessions available') { return; }
        if ($line.StartsWith('--------------')) {
            $started = $true;
            continue; }
        if (!$started) {
            continue; }
        if ($line.StartsWith('Path: ')) {
            $retVal.Path = $line.Substring('Path: '.Length).Trim();
            continue; }
        if ($line.StartsWith('Owner: ')) {
            $retVal.Owner = $line.Substring('Owner: '.Length).Trim();
            [int] $firstSpace = $retVal.Owner.IndexOf(' ');
            $retVal.Owner = $retVal.Owner.Substring(0, $firstSpace).Trim();
            continue; }
        if ($line.StartsWith('Config name: ')) {
            $retVal.Name = $line.Substring('Config name: '.Length).Trim();
            continue; }
        if ($line.StartsWith('Session name: ')) {
            $retVal.Session = $line.Substring('Session name: '.Length).Trim();
            continue; }
        if ($line.StartsWith('Status: ')) {
            $retVal.Status = $line.Substring('Status: '.Length).Trim();
            continue; } }
    Write-Output $retVal;
}

$session = Script:Get-Session;
if ($null -eq $session) { exit; }
[string[]] $output = & openvpn3 session-manage --session-path "$($session.Path)" --disconnect;
[bool] $succeeded = $false;
foreach ($line in $output) {
    [string] $line = $line.Trim();
    if ($line -eq 'session-manage: ** ERROR ** Session not found') {
        Write-Error -Message $line;
        Write-Output $session;
        exit; }
    if ($line -eq 'Initiated session shutdown.') {
        $succeeded = $true;
        break; } }
if (!$succeeded) {
    Write-Error -Message 'OpenVPN connection termination failed.';
    Write-Output $output; }