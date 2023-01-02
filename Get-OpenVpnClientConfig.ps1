<#
#>
PARAM (
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $MachineName,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string] $OpenVPNServerName = 'my.cool.server',

    [Parameter(Mandatory = $false)]
    [ValidateNotNull()]
    [int] $PortNumber = 1194,

    [Parameter(Mandatory = $false)]
    [ValidateSet('UDP', 'TCP')]
    [ValidateNotNullOrEmpty()]
    [string] $Protocol = 'UDP',

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string] $BASE_EASYRSA_PATH = '/etc/openvpn/easy-rsa'    
)

[string] $certPath = [System.IO.Path]::Combine($BASE_EASYRSA_PATH, 'pki', 'issued', "$($MachineName).crt");
[string] $keyPath = [System.IO.Path]::Combine($BASE_EASYRSA_PATH, 'pki', 'private', "$($MachineName).key");
[string] $caCert = [System.IO.Path]::Combine($BASE_EASYRSA_PATH, 'pki', 'ca.crt');
[string] $taKey = [System.IO.Path]::Combine($BASE_EASYRSA_PATH, 'pki', 'ta.key');

$bld = [System.Text.StringBuilder]::new();
$bld.AppendLine('client') | Out-Null;
$bld.AppendLine('dev tun') | Out-Null;
$bld.AppendLine("proto $($Protocol.ToLower())") | Out-Null;
$bld.AppendLine("remote $($OpenVPNServerName) $($PortNumber)") | Out-Null;
$bld.AppendLine('resolv-retry infinite') | Out-Null;
$bld.AppendLine('nobind') | Out-Null;
$bld.AppendLine('persist-key') | Out-Null;
$bld.AppendLine('persist-tun') | Out-Null;
$bld.AppendLine('mute-replay-warnings') | Out-Null;
$bld.AppendLine('<ca>') | Out-Null;
[string[]] $crtLines = openssl x509 -inform PEM -in "$($caCert)";
foreach ($line in $crtLines) {
    [string] $line = $line;
    $bld.AppendLine($line) | Out-Null;
}
$bld.AppendLine('</ca>') | Out-Null;
$bld.AppendLine('<cert>') | Out-Null;
[string[]] $crtLines = openssl x509 -inform PEM -in "$($certPath)";
foreach ($line in $crtLines) {
    [string] $line = $line;
    $bld.AppendLine($line) | Out-Null;
}
$bld.AppendLine('</cert>') | Out-Null;
$bld.AppendLine('<key>') | Out-Null;
[string[]] $crtLines = cat "$($keyPath)";
foreach ($line in $crtLines) {
    [string] $line = $line;
    $bld.AppendLine($line) | Out-Null;
}
$bld.AppendLine('</key>') | Out-Null;
$bld.AppendLine('remote-cert-tls server') | Out-Null;
$bld.AppendLine('<tls-auth>') | Out-Null;
[string[]] $crtLines = cat "$($taKey)";
foreach ($line in $crtLines) {
    [string] $line = $line.Trim();
    if ($line.StartsWith('#')) {
        continue;
    }
    $bld.AppendLine($line) | Out-Null;
}
$bld.AppendLine('</tls-auth>') | Out-Null;
$bld.AppendLine('key-direction 1') | Out-Null;
$bld.AppendLine('verb 3') | Out-Null;
Write-Output $bld.ToString();