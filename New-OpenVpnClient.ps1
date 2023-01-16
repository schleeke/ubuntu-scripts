<#
.SYNOPSIS
  Creates certificates for a new OpenVPN client.
.DESCRIPTION
  Creates a client certificate (generate-client-full) for OpenVPN
  using easy-rsa.
.PARAMETER Password
  The password for the new client's private key.
.PARAMETER CAPassword
  The password for the certificate authority private key.
.PARAMETER MachineName
  The name of the new OpenVPN client.
.PARAMETER NoPassword
  If set, no password for the client's private key is set.
  
  If a client configuration file with such a key is used,
  no password protection is applied to that OpenVPN access.
  Anyway - you can revoke that certificate to prevent
  a rogue key/config from connecting to the OpenVPN server.
.PARAMETER BASE_EASYRSA_PATH
  The path to the easy-rsa directory. Hopefully beneath the
  /etc/openvpn directory.
.COMPONENT
  easy-rsa
.OUTPUTS
  Nothing, just text on the console.
#>
[CmdletBinding(DefaultParameterSetName = 'WithPwd')]
PARAM (
    [Parameter(ParameterSetName = 'WithPwd')]
    [securestring] $Password,

    [Parameter(ParameterSetName = 'WithPwd')]
    [Parameter(ParameterSetName = 'WithoutPwd')]
    [securestring] $CAPassword,

    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'WithPwd')]
    [Parameter(ParameterSetName = 'WithoutPwd')]
    [ValidateNotNullOrEmpty()]
    [string] $MachineName,

    [Parameter(Mandatory = $false, ParameterSetName = 'WithoutPwd')]
    [switch] $NoPassword,

    [Parameter(Mandatory = $false, ParameterSetName = 'WithPwd')]
    [Parameter(ParameterSetName = 'WithoutPwd')]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container })]
    [string] $BASE_EASYRSA_PATH = '/etc/openvpn/easy-rsa',

    [Parameter(Mandatory = $false, ParameterSetName = 'WithPwd')]
    [Parameter(ParameterSetName = 'WithoutPwd')]
    [ValidateNotNullOrEmpty()]
    [string] $FILE_OWNER = 'root:openvpn-admin'
)

if ($null -eq $Password) {
  $Password = Read-Host -AsSecureString -Prompt 'Enter password for client config ';
}
if ($null -eq $CAPassword) {
  $CAPassword = Read-Host -AsSecureString -Prompt 'Enter password for CA private key ';
}
Write-Host 'Creating new OpenVPN client certificate...';
$currentLocation = Get-Location;
Set-Location -LiteralPath $BASE_EASYRSA_PATH;
[string] $clientPassword = ConvertFrom-SecureString -SecureString $Password -AsPlainText -WarningAction SilentlyContinue;
[string] $capwd = ConvertFrom-SecureString -SecureString $CAPassword -AsPlainText -WarningAction SilentlyContinue;
[System.Environment]::SetEnvironmentVariable('EASYRSA_PASSIN', "pass:$($capwd)");

if ($PSCmdlet.ParameterSetName -eq 'WithPwd') {
    [System.Environment]::SetEnvironmentVariable('EASYRSA_PASSOUT', "pass:$($clientPassword)");
    & './easyrsa' 'build-client-full' $MachineName;    
}
else {
    [System.Environment]::SetEnvironmentVariable('EASYRSA_PASSOUT', "pass:$($clientPassword)");
    & './easyrsa' 'build-client-full' 'nopass' $MachineName;    
}
[System.Environment]::SetEnvironmentVariable('EASYRSA_PASSIN', '');
if ($PSCmdlet.ParameterSetName -eq 'WithPwd') {
    [System.Environment]::SetEnvironmentVariable('EASYRSA_PASSOUT', '');
}
[string] $filePath = [System.IO.Path]::Combine($BASE_EASYRSA_PATH, 'pki', 'issued', "$($MachineName).crt");
[bool] $succeeded = Test-Path -LiteralPath $filePath -PathType Leaf;
Set-Location $currentLocation;
if (!$succeeded) {
    Set-Location $currentLocation;
    [System.Environment]::ExitCode = 1;
    exit 1;
}
Write-Host "Altering created files owner ($($FILE_OWNER))...";
& 'sudo' 'chown' $FILE_OWNER $filePath;
$filePath = [System.IO.Path]::Combine($BASE_EASYRSA_PATH, 'pki', 'private', "$($MachineName).key");
& 'sudo' 'chown' $FILE_OWNER $filePath;
$filePath = [System.IO.Path]::Combine($BASE_EASYRSA_PATH, 'pki', 'reqs', "$($MachineName).req");
& 'sudo' 'chown' $FILE_OWNER $filePath;
Write-Host 'Altering group rights on created files...';
$filePath = [System.IO.Path]::Combine($BASE_EASYRSA_PATH, 'pki', 'issued', "$($MachineName).crt");
& 'sudo' 'chmod' 'g+rw' $filePath;
$filePath = [System.IO.Path]::Combine($BASE_EASYRSA_PATH, 'pki', 'private', "$($MachineName).key");
& 'sudo' 'chmod' 'g+rw' $filePath;
$filePath = [System.IO.Path]::Combine($BASE_EASYRSA_PATH, 'pki', 'reqs', "$($MachineName).req");
& 'sudo' 'chmod' 'g+rw' $filePath;
Set-Location $currentLocation;