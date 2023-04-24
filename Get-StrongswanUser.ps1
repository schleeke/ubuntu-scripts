<#
#>
[CmdletBinding()]
PARAM ()

[string[]] $lines = Get-Content -LiteralPath '/etc/ipsec.secrets';
foreach ($line in $lines) {
    [string] $line = $line.Trim();
    if ([string]::IsNullOrEmpty($line)) {
        continue; }
    if ($line -notlike '*: EAP "*') {
        continue;
    }
    [int] $index = $line.IndexOf(': EAP "');
    [string] $userName = $line.Substring(0, $index).Trim();
    [string] $usrPwd = $line.Substring($index + ': EAP "'.Length);
    $usrPwd = $usrPwd.Substring(0, $usrPwd.Length - 1).Trim();
    $retVal = [PSCustomObject]@{
        Name = $userName
        Password = $usrPwd
    };
    Write-Output $retVal;
}