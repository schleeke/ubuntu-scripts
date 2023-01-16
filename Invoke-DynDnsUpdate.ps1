<#
.SYNOPSIS
  Updates the A record of a DynDNS server.
.DESCRIPTION
  Calls the update-request of the DynDNS API to set an DNS server's A record.
#>
[CmdletBinding(DefaultParameterSetName = 'ByConfig')]
PARAM (
    [Parameter(Mandatory = $true, ParameterSetName = 'ByUri')]
    [ValidateNotNullOrEmpty()]
    [string] $Uri,

    [Parameter(Mandatory = $true, ParameterSetName = 'ByUri')]
    [Parameter(ParameterSetName = 'ByConfig')]
    [ValidateNotNullOrEmpty()]
    [string] $DomainName,

    [Parameter(Mandatory = $true, ParameterSetName = 'ByUri')]
    [Parameter(ParameterSetName = 'ByConfig')]
    [ValidateNotNullOrEmpty()]
    [string] $UserName,

    [Parameter(Mandatory = $true, ParameterSetName = 'ByUri')]
    [Parameter(ParameterSetName = 'ByConfig')]
    [ValidateNotNullOrEmpty()]
    [string] $Pass,

    [Parameter(Mandatory = 'true', ParameterSetName = 'ByConfig')]
    [ValidateSet('Strato', 'No-IP')]
    [string] $Provider
)

$STRATO_CFG = [PSCustomObject]@{
    Uri = 'https://dyndns.strato.com'
    UserAgent = 'SchleeKe - Invoke-DynDnsUpdate - 1.0.0.0 - https://github.com/schleeke/ubuntu-scripts'
}
$NOIP_CFG = [PSCustomObject]@{
    Uri = ''
    UserAgent = 'SchleeKe DynDNS/6.3-1.0.0.0 schleeke@github.com'
}

function script:Get-ExternalIp() {
    [string] $EXTERNAL_IP_URI = 'https://myexternalip.com/';
    [Microsoft.PowerShell.Commands.BasicHtmlWebResponseObject] $webResult = Invoke-WebRequest -UseBasicParsing -Uri $EXTERNAL_IP_URI -UseDefaultCredentials;
    if ($webResult.StatusCode -ne 200) {
        Write-Error -Message "Unable to get external IP address. HTTP answer $($webResult.StatusCode).";
        return;
    }
    [string[]] $lines = $webResult.Content.Split([System.Environment]::NewLine);
    if ($lines.Count -lt 5) {
        Write-Error -Message 'Unable to parse the HTML content.';
        return;
    }
    [string] $externalIpAddress = [string]::Empty;
    foreach ($line in $lines) {
        [string] $line = $line.Trim();
        if ([string]::IsNullOrEmpty($line)) { continue; }
        if ($line.StartsWith('<title>My External IP address -')) {
            $line = $line.Substring('<title>My External IP address -'.Length).Trim();
            if ($line.EndsWith('</title>')) {
                $line = $line.Substring(0, $line.Length - '</title>'.Length).Trim();
            }
            [bool] $validIp = $false;
            try {
                [ipaddress]$ipaddr = [ipaddress]$line;
                $validIp = $true;
            }
            catch {
                $validIp = $false;
            }
            if ($validIp) {
                $externalIpAddress = $line;
                break;
            }
        }
    }
    if ([string]::IsNullOrEmpty($externalIpAddress)) {
        Write-Error 'Unable to determine external IP address.';
        return;
    }
    Write-Output $externalIpAddress;    
}

function script:Get-UpdateUri() {
    [string] $retVal = '';
    switch ($PSCmdlet.ParameterSetName) {
        'ByUri' { $retVal = $Uri; }
        'ByConfig' {
            switch ($Provider) {
                'Strato' { $retVal = $STRATO_CFG.Uri; }
                'No-IP' { $retVal = $NOIP_CFG.Uri; }
            }
        }
    }
    if ($retVal.EndsWith('\')) {
        $retVal = $retVal.Substring(0, $retVal.Length - 1);        
    }
    Write-Output $retVal;
}


$externalIpAddress = script:Get-ExternalIp;
$apiUrl = script:Get-UpdateUri;
$apiUrl = "$($apiUrl)/nic/update?hostname=$($DomainName)&myip=$($externalIpAddress)";
$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("$($UserName):$($Pass)"));
$encodedCreds = "Basic $($encodedCreds)";
$headers = @{ Authorization = $encodedCreds };
if ($PSCmdlet.ParameterSetName -eq 'ByConfig') {
    [string] $usrAgent = '';
    switch ($Provider) {
        'Strato' { $usrAgent = $STRATO_CFG.UserAgent; }
        'No-IP' { $usrAgent = $NOIP_CFG.UserAgent; }
    }
    $webResult = Invoke-WebRequest -Uri $apiUrl -Headers $headers -UseBasicParsing -UseDefaultCredentials -UserAgent $usrAgent;
}
else {
    $webResult = Invoke-WebRequest -Uri $apiUrl -Headers $headers -UseBasicParsing -UseDefaultCredentials;
}
if ($webResult.StatusCode -ne 200) {
    Write-Error -Message "DynDNS update failed. HTTP Code $($webResult.StatusCode).";
    return;
}
$encodedCreds = $webResult.Content.Trim();
if ($encodedCreds.StartsWith('good') -or $encodedCreds.StartsWith('nochg')) {
    return;
}
Write-Error -Message "An DynDNS update error occured. Server answer: $($encodedCreds).";