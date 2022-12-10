<#
.SYNOPSIS
  Initializes an OpenVPN connection.
.DESCRIPTION
  Executes 'openvpn3 session-start --config [...] --dco true' and uses the appropriate configuration path based on the parameter values.
.PARAMETER ConfigurationName
  The name of the existing OpenVPN configuration that shall be used for initiating the connection.
.PARAMETER InputObject
  The configuration instance as returned by the Get-OpenVpnConfiguration.ps1 script.
  In fact, any object instance that has a 'Name' property with a value corresponding to an existing OpenVPN configuration can be used.
.PARAMETER Any
  If set, no specification of a certain configuration by name or instance is needed for initializing a VPN connection.
  The first available existing configuration will be used instead.
.EXAMPLE
  ./Start-OpenVpnConnection.ps1 -Any

  Initializes an OpenVPN connection with the first available existing configuration.
.EXAMPLE
  ./Start-OpenVpnConnection.ps1 -ConfigurationName 'MyCoolOpenVpnConfig.ovpn'

  Initializes a connection for the existing connection named 'MyCoolOpenVpnConfig.ovpn'.
.EXAMPLE
  ./Get-OpenVpnConfiguration.ps1 -Name 'MyCoolOpenVpnConfig.ovpn' | ./Start-OpenVpnConnection.ps1
- or -
  PS > $myCoolConfig = ./Get-OpenVpnConfiguration.ps1 -Name 'MyCoolOpenVpnConfig.ovpn'
  PS > ./Start-OpenVpnConnection.ps1 -InputObject $myCoolConfig

  Initializes a connection for the existing connection named 'MyCoolOpenVpnConfig.ovpn'.
.NOTES
  Sources: https://github.com/schleeke/ubuntu-scripts
#>
[CmdletBinding(DefaultParameterSetName='ByConfig')]
PARAM (
    [Parameter(Position=0, ParameterSetName='ByName')]
    [string] $ConfigurationName,

    [Parameter(Position=0, ParameterSetName='ByConfig', ValueFromPipeline=$true)]
    $InputObject,

    [Parameter(ParameterSetName='ByName')]
    [Parameter(ParameterSetName='ByConfig')]
    [switch] $Any
)

function Script:Get-Config() {
    [string[]] $output = & openvpn3 configs-list;
    [bool] $succeeded = $false;
    [bool] $reachedStart = $false;
    [int] $lineCounter = 0;
    $configurations = @();
    $currentConfig = [PSCustomObject]@{
        Name = ''
        Path = ''
        Used = 0
        Owner = '' };
    foreach ($line in $output) {
        [string] $line = $line.Trim();
        if (!$reachedStart -and $line -eq 'Configuration path') {
            $succeeded = $true;
            continue; }
        if (!$reachedStart -and $succeeded -and $line.StartsWith('-------------------')) {
            $reachedStart = $true;
            $lineCounter = 0;
            continue; }
        if (!$reachedStart) {
            continue; }
        if ([string]::IsNullOrEmpty($line) -and $lineCounter -gt 0) { #assuming an empty line between config-sections...
            $lineCounter = 0;
            $configurations += $currentConfig;
            $currentConfig = [PSCustomObject]@{
                Name = ''
                Path = ''
                Used = 0
                Owner = '' };        
            continue; }
        $lineCounter++;
        switch ($lineCounter) {
            1 {
                $currentConfig.Path = $line; }
            2 {
                [int] $lastSpaceIndex = $line.LastIndexOf(' ');
                if ($lastSpaceIndex -lt 16) {
                    continue; }
                [string] $numberPart = $line.Substring($lastSpaceIndex + 1);
                [int] $used = 0;
                [bool] $isNumber = [int]::TryParse($numberPart, [ref] $used);
                if (!$isNumber) {
                    continue; }
                $currentConfig.Used = $used; }
            3 {
                [int] $firstSpaceIndex = $line.IndexOf(' ');
                if ($firstSpaceIndex -lt 1) {
                    continue; }
                [string] $cfgName = $line.Substring(0, $firstSpaceIndex).Trim();
                $firstSpaceIndex = $line.LastIndexOf(' ');
                if ($firstSpaceIndex -lt 1) {
                    continue; }
                [string] $creator = $line.Substring($firstSpaceIndex + 1).Trim();
                $currentConfig.Name = $cfgName;
                $currentConfig.Owner = $creator; } } }
    if ($currentConfig.Name -ne '') {
        $configurations += $currentConfig; }    
    Write-Output $configurations;
}

$configurations = Script:Get-Config;
$currentConfig = $null;
foreach ($cfg in $configurations) {
    switch ($PSCmdlet.ParameterSetName) {
        'ByName' {
            if ($cfg.Name -eq $ConfigurationName) { $currentConfig = $cfg; break;} }
        'ByConfig' {
            if ($cfg.Name -eq $InputObject.Name) { $currentConfig = $cfg; break; } } } }
if ($null -eq $currentConfig -and $Any.IsPresent -eq $false) {
    Write-Warning -Message "No matching configuration found. Use the 'Any' switch to use the first available configuration.";
    exit; }
if ($null -eq $currentConfig -and $Any.IsPresent) {
    $currentConfig = $configurations[0]; }
if ($null -eq $currentConfig) {
    Write-Warning -Message 'No matching configuration found.';
    exit; }
[string[]] $output = & openvpn3 session-start --config "$($currentConfig.Name)" --dco true;
[bool] $succeeded = $false;
foreach ($line in $output) {
    [string] $line = $line.Trim();
    if ($line -eq 'Connected') {
        $succeeded = $true;
        break; } }
if (!$succeeded) {
    Write-Error -Message 'The connection could not be established.';
    Write-Output $output; }