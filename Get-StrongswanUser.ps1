<#
.SYNOPSIS
  Returns the specified strongswan user credentials.
.DESCRIPTION
  Parses /etc/ipsec.secrets for users and their passwords.
.PARAMETER UserName
  The name of the user to return. All users will be returned if
  no UserName is specified.
#>
[CmdletBinding()]
PARAM (
    [Parameter()] [string] $UserName
)

[string[]] $lines = Get-Content -LiteralPath '/etc/ipsec.secrets';
foreach ($line in $lines) {
    [string] $line = $line.Trim();
    if ([string]::IsNullOrEmpty($line)) {
        continue; }
    if ($line -notlike '*: EAP "*') {
        continue; }
    [int] $index = $line.IndexOf(': EAP "');
    [string] $usrName = $line.Substring(0, $index).Trim();
    [string] $usrPwd = $line.Substring($index + ': EAP "'.Length);
    $usrPwd = $usrPwd.Substring(0, $usrPwd.Length - 1).Trim();
    $retVal = [PSCustomObject]@{
        Name = $usrName
        Password = $usrPwd };
    if ([string]::IsNullOrEmpty($UserName)) {
        Write-Output $retVal; }
    elseif ($usrName.Equals($UserName, [System.StringComparison]::CurrentCultureIgnoreCase)) {
        Write-Output $retVal; }    
}