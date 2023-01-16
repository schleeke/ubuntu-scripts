<#
.SYNOPSIS
  Alters the ownership and rights of the OpenVPN directory.
.DESCRIPTION
  Sets the ownership to the given group and alters the group's rights
  to match the user's ones.
.PARAMETER LiteralPath
  The literal path to the OpenVPN directory.
.PARAMETER GroupName
  The name of the group which should become owner of the files.
#>
PARAM (
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container })]
    [string] $LiteralPath = '/etc/openvpn/',

    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string] $GroupName = 'openvpn-admin',

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string] $EASYRSA_BIN_PATH = '/etc/openvpn/easy-rsa/easyrsa'
)

function Script:Set-OwnershipAndRights($Object, [string] $GroupName) {
    [string] $typeName = $Object.GetType().Name;
    if ($typeName -eq 'DirectoryInfo') {
        [System.IO.DirectoryInfo] $Object = $Object;
        Write-Information -MessageData "Altering directory [$($Object.FullName)] owner/rights for group '$($GroupName)'..." -InformationAction Continue;
    }
    elseif ($typeName -eq 'FileInfo') {
        [System.IO.FileInfo] $Object = $Object;
        Write-Information -MessageData "Altering file [$($Object.FullName)] owner/rights for group '$($GroupName)'..." -InformationAction Continue;
    }    
    sudo chown "root:$($GroupName)" $Object.FullName;
    [bool] $canRead = $Object.UnixFileMode.HasFlag([System.IO.UnixFileMode]::UserRead);
    [bool] $canWrite = $Object.UnixFileMode.HasFlag([System.IO.UnixFileMode]::UserWrite);
    [bool] $canExecute = $Object.UnixFileMode.HasFlag([System.IO.UnixFileMode]::UserExecute);
    $modes = [string]::Empty;
    if ($canRead) { $modes += 'r'; }
    if ($canWrite) { $modes += 'w'; }
    if ($canExecute) { $modes += 'x'; }
    sudo chmod "g+$($modes)" $Object.FullName;
    if ($typeName -eq 'DirectoryInfo') {
        [System.IO.DirectoryInfo] $Object = $Object;
        [System.IO.FileInfo[]] $files = $Object.GetFiles();
        [System.IO.DirectoryInfo[]] $subDirs = $Object.GetDirectories();
        foreach ($f in $files) {
            Script:Set-OwnershipAndRights -Object $f -GroupName $GroupName;
        }
        foreach ($d in $subDirs) {
            Script:Set-OwnershipAndRights -Object $d -GroupName $GroupName;            
        }
    }
}

[System.IO.DirectoryInfo] $openvpnDirectory = [System.IO.DirectoryInfo]::new($LiteralPath);
Script:Set-OwnershipAndRights -Object $openvpnDirectory -GroupName $GroupName;
sudo chmod +x $EASYRSA_BIN_PATH;