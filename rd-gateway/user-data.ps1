<powershell>
Install-WindowsFeature RDS-Gateway,RSAT-RDS-Gateway,RSAT-ADDS,RSAT-DNS-Server
Import-Module RemoteDesktopServices
$GroupName='Administrators';$DomainNetBiosName='BUILTIN'
New-Item -path RDS:\GatewayServer\CAP -Name Default-CAP -UserGroups "$GroupName@$DomainNetBiosName" -AuthMethod 1
New-Item -Path RDS:\GatewayServer\RAP -Name Default-RAP -UserGroups "$GroupName@$DomainNetBiosName" -ComputerGroupType 2
Restart-Service tsgateway
Rename-Computer -NewName {computer_name} -Force
</powershell>