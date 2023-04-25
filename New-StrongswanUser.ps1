<#
.SYNOPSIS
  Adds a new strongswan user.
.DESCRIPTION
  Adds a new line with a username and password to the /etc/ipsec.secrets.
.PARAMETER UserName
  The name of the new user.
.PARAMETER Password
  The password for the new user.
#>
PARAM (
    [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string] $UserName,
    [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string] $Password
)
$existingUser = .\Get-StrongswanUser.ps1 -UserName $UserName;
[bool] $userExists = ($null -ne $existingUser);
if ($userExists) {
    Write-Warning 'The user already exists.';
    exit; }
[string] $newLine = "$($UserName) : EAP ""$($Password)""";
Add-Content -LiteralPath '/etc/ipsec.secrets' -Value $newLine -Force;