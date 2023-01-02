<#
#>
PARAM (
    [Parameter()]
    [string] $MachineName,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string] $BASE_EASYRSA_PATH = '/etc/openvpn/easy-rsa'
)

[string] $issuedPath = [System.IO.Path]::Combine($BASE_EASYRSA_PATH, 'pki', 'issued');
[System.IO.DirectoryInfo] $issuedDir = [System.IO.DirectoryInfo]::new($issuedPath);
[System.IO.FileInfo[]] $certificates = $issuedDir.GetFiles('*.crt');
$certificates = $certificates | Sort-Object -Property BaseName;
foreach ($cert in $certificates) {
    [System.IO.FileInfo] $cert = $cert;
    if ([string]::IsNullOrEmpty($MachineName)) {
        Write-Output $cert.BaseName;
    }
    elseif ($cer.BaseName -ne $MachineName) {
        continue;
    }
    else {
        Write-Output $cert.BaseName;
    }
}