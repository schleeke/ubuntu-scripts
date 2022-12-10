<#
.SYNOPSIS
  Returns a specific or all existing OpenVPN configuration(s).
.DESCRIPTION
  Parses the output of the 'openvpn3 configurations-list' command and returns the result(s) based on
  the parameter values as object(s) for further use within the powershell pipeline.
.PARAMETER Name
  The existing configuration's name.
.PARAMETER Path
  The path of an existing configuration.
.NOTES
  Sources: https://github.com/schleeke/ubuntu-scripts
.OUTPUTS
  An array of or a single PSCustomObject with the following properties:
  Name, Path, Used, Owner.
#>
[CmdletBinding(DefaultParameterSetName='ByName', SupportsShouldProcess=$false)]
PARAM (
    [Parameter(Position=0, ValueFromPipeline=$true, ParameterSetName='ByName')]
    [string] $Name,

    [Parameter(Position=0, ParameterSetName='ByPath')]
    [string] $Path
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
if ([string]::IsNullOrEmpty($Name) -and [string]::IsNullOrEmpty($Path)) {
    Write-Output $configurations;
    exit; }
foreach ($cfg in $configurations) {
    switch ($PSCmdlet.ParameterSetName) {
        'ByName' { if ($cfg.Name -eq $Name) { Write-Output $cfg; } }
        'ByPath' { if ($cfg.Path -eq $Path) { Write-Output $cfg; } } } }