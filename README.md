# ubuntu-scripts

A collection of powershell-scripts for being used within ubuntu/powershell.  
Basically my daily-usage-repository - i have included the repositorie's directory into my *$PATH* variable and have my scripts accessible if i need them on other machines...  

All scripts have a document/comment header so the call of
~~~powershell
Get-Help <scriptname>
~~~
will show parameter and extended information.  

## Scripts

| Name                         | Purpose | Tags    |
|------------------------------|---------|-----------|
| Get-OpenVpnConfiguration.ps1 | Returns one or all existing client configurations. | *OpenVPN* |
| Start-OpenVpnConnection.ps1  | Initializes a VPN connection. | *OpenVPN* |
| Stop-OpenVpnConnection.ps1   | Terminates an open VPN connection. | *OpenVPN* |