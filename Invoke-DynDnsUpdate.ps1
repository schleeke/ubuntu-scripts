<#
#>
PARAM (
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string] $Uri = 'https://dyndns.strato.com/nic/update',

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $DomainName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $UserName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $Pass
)

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
$stratoUrl = "$($Uri)?hostname=$($DomainName)&myip=$($externalIpAddress)";
$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("$($UserName):$($Pass)"));
$encodedCreds = "Basic $($encodedCreds)";
$headers = @{
    Authorization = $encodedCreds
}
$webResult = Invoke-WebRequest -Uri $stratoUrl -Headers $headers -UseBasicParsing -UseDefaultCredentials;
if ($webResult.StatusCode -ne 200) {
    Write-Error -Message "DynDNS update failed. HTTP Code $($webResult.StatusCode).";
    return;
}
$encodedCreds = $webResult.Content.Trim();
if ($encodedCreds.StartsWith('good') -or $encodedCreds.StartsWith('nochg')) {
    return;
}
Write-Error -Message "An DynDNS update error occured. Server answer: $($encodedCreds).";