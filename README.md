# OpenVPN management scripts
A bunch of powershell scripts for managing users/certificates/client-configs for OpenVPN in linux/ubuntu. Should work on other OSes / distros, as well.

## Preamble
The scripts respectively the author makes a few assumptions about the environment the scripts are used in.  
For the sake of better management, the author created a group that owns all OpenVPN- and easy-rsa-files and has the same rights as the file owner (user).<br/><br/>

The easy-rsa location is also assumed to be beneath the OpenVPN directory (*/etc/openvpn/*). Symbolic links might be a good idea to be up-to-date in case of upgrades to the package...<br/><br/>

A script might have parameters that are named like constants or environment variables and are all in capital letters (e.g. *BASE_EASYRSA_PATH*). These parameters are not mandatory and have a predefined value that can be changed within the 'source code' to fit to the environment (or - of course - can be set while calling the script).

## System alterations
The following changes to the system need to be applied in order for the scripts to work:<br/><br/>

1. Create a group for the OpenVPN/Easy-RSA management and add users to it:
```POSIX
sudo addgroup openvpn-admin
sudo adduser $USER openvpn-admin
sudo adduser root openvpn-admin
```

2. Alter the ownerships and rights of the OpenVPN/Easy-RSA binaries/files:

```Powershell
.\Set-OpenVpnRightsAndOwner.ps1
```

3. Add the OpenVPN management group to the sudoers and exclude a few binaries from asking for the user's password when using sudo:
    1. Open the file /etc/sudoers (sudo) [ or create a new file beneath */etc/sudoers.d/* ]
    2. Add the following lines:
    ```
    Cmnd_Alias OPENVPN_CMD = /etc/openvpn/easy-rsa/easyrsa, /usr/bin/chmod, /usr/bin/chown
    %openvpn-admin ALL=(ALL) NOPASSWD: OPENVPN_CMD
    ```
    3. Reboot
<br/><br/>
> Using the exceptions for the sudo binaries is obviosly not the best way to to and will be changed so that the sudo password can be passed by STDIN or whatever...

<br/><br/>
## General help using the scripts
All scripts are commented in a way that the Get-Help CmdLet can provide detailed information for the given script. Each script comes with at least one example.

## Set-OpenVpnRightsAndOwner
Sets the given directory (and child-) ownership to root (user) and the specified group. It also mirrors all user rights to the group rights.

## New-OpenVpnClient
The script creates a new public/private key pair for a new machine/OpenVPN client. The generated key can than be used within a client configuration file.

## Get-OpenVpnClientConfig
Creates the OpenVPN Client Config file content for a specific client.

## Get-OpenVpnClient
Gets one or all existing/active clients.