<#
.SYNOPSIS
  Removes as client/machine from the OpenVPN PKI.
.DESCRIPTION
  Uses easy-rsa to remove a certain public/private client key pair
  and updates the CRL.
.PARAMETER MachineName
  The name of the client/machine that should be removed/revoked.
.PARAMETER CAPassword
  The password for the CA private key.
.PARAMETER Reason
  The reason for the revokation.
.PARAMETER BASE_EASYRSA_PATH
  The path to the easy-rsa directory. Hopefully beneath the /etc/openvpn directory.
.COMPONENT
  easy-rsa
#>
PARAM (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $MachineName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNull()]
    [securestring] $CAPassword,

    [Parameter(Mandatory = $false)]
    [ValidateSet('unspecified', 'keyCompromise', 'CACompromise', 'affiliationChanged', 'superseded', 'cessationOfOperation', 'certificateHold')]
    [string] $Reason = 'keyCompromise',

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container })]
    [string] $BASE_EASYRSA_PATH = '/etc/openvpn/easy-rsa'
)

[string[]] $existingClients = @();
[string] $scriptPath = [System.IO.Path]::Combine($PSScriptRoot, 'Get-OpenVpnClient.ps1');
[string[]] $existingClients = & $scriptPath;
if (!($existingClients -contains $MachineName)) {
    return;
}
$currentLocation = Get-Location;
Set-Location -LiteralPath $BASE_EASYRSA_PATH;
& './easyrsa' 'revoke' $MachineName $Reason;
[string] $capwd = ConvertFrom-SecureString -SecureString $CAPassword -AsPlainText -WarningAction SilentlyContinue;
[System.Environment]::SetEnvironmentVariable('EASYRSA_PASSIN', "pass:$($capwd)");
& './easyrsa' 'gen-crl';
[System.Environment]::SetEnvironmentVariable('EASYRSA_PASSIN', '');
Set-Location $currentLocation;