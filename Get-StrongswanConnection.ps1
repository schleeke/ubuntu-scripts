<#
.SYNOPSIS
  Gets the active strongswan client connections.
.DESCRIPTION
  Parses 'ipsec statusall' to retrieve information concerning connected clients.
#>
[CmdletBinding()]
PARAM ()
[string[]] $lines = ipsec statusall;
[int] $minIndex = 0;
[int] $maxIndex = $lines.Count - 1;
[bool] $sectionReached = $false;
for ($counter = $minIndex; $counter -le $maxIndex; $counter++) {
    [string] $currentLine = $lines[$counter].Trim();
    if ([string]::IsNullOrEmpty($currentLine)) {
        continue; }
    if ($currentLine.StartsWith('Security Associations (') -and $currentLine.EndsWith('):')) {
        $sectionReached = $true;        
        [string] $upClients = $currentLine.Substring('Security Associations ('.Length);
        $upClients = $upClients.Substring(0, $upClients.Length - '):'.Length);
        [string[]] $parts = $upClients -split ',';
        $upClients = $parts[0].Trim();
        [int] $spaceIndex = $upClients.IndexOf(' ');
        if ($spaceIndex -gt 0) {
            $upClients = $upClients.Substring(0, $spaceIndex).Trim();
            Write-Host "$($upClients)" -ForegroundColor Green -NoNewline;
            Write-Host " active connection(s):"; }
        continue; }
    if (!$sectionReached) {
        continue; }
    if ($currentLine.Contains('Remote EAP identity: ')) {
        $newUser = [PSCustomObject]@{
            Name = ''
            Duration = ''
            ServerInternal = ''
            ServerExternal = ''
            ClientInternal = ''
            ClientExternal = '' };
        [string] $conInfo = $lines[$counter - 1].Trim();
        [int] $index = $currentLine.IndexOf('Remote EAP identity: ') + 'Remote EAP identity: '.Length;
        $newUser.Name = $currentLine.Substring($index);
        $index = $conInfo.IndexOf('ESTABLISHED ') + 'ESTABLISHED '.Length;
        [string] $tmp = $conInfo.Substring($index);
        $index = $tmp.IndexOf(',');
        $newUser.Duration = $tmp.Substring(0, $index);
        $index = $conInfo.IndexOf(', ');
        $tmp = $conInfo.Substring($index + ', '.Length);
        $index = $tmp.IndexOf('[');
        $newUser.ServerInternal = $tmp.Substring(0, $index);
        $tmp = $tmp.Substring($index + 1);
        $index = $tmp.IndexOf(']');
        $newUser.ServerExternal = $tmp.Substring(0, $index);
        $tmp = $tmp.Substring($index + 1);
        $index = $tmp.IndexOf('...') + '...'.Length;
        $tmp = $tmp.Substring($index);
        $index = $tmp.IndexOf('[');
        $newUser.ClientExternal = $tmp.Substring(0, $index);
        $tmp = $tmp.Substring($index + 1);
        $newUser.ClientInternal = $tmp.Substring(0, $tmp.Length - 1);
        Write-Output $newUser; }
}