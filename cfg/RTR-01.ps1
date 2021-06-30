$nom = "RTR-01"

if ($nom -notlike $env:computername)
{
    Install-WindowsFeature Routing -IncludeManagementTools
    Rename-Computer $nom
    Set-NetFirewallRule *ICMP4* -Enabled True
    Restart-Computer
}
else
{
    Install-RemoteAccess -VpnType RoutingOnly
    $int="WAN"
    Rename-NetAdapter -Name "Ethernet" -NewName $int
    netsh interface ipv4 set address $int static 192.168.255.8/24

    $int="Arc-CLI"
    Rename-NetAdapter -Name "Ethernet 2" -NewName $int
    netsh interface ipv4 set address $int static 192.168.12.254/24

    $int="Arc-SRV"
    Rename-NetAdapter -Name "Ethernet 3" -NewName $int
    netsh interface ipv4 set address $int static 192.168.8.254/24

    Get-NetAdapter | Set-NetIPInterface -Forwarding Enabled

    #Routes
    New-NetRoute -DestinationPrefix "0.0.0.0/0" -InterfaceAlias "WAN" -NextHop 192.168.255.254
    #New-NetRoute -DestinationPrefix "192.168.12.0/24" -InterfaceAlias "Arc-CLI" -NextHop 192.168.12.254
    #New-NetRoute -DestinationPrefix "192.168.8.0/24" -InterfaceAlias "Arc-SRV" -NextHop 192.168.8.254
    New-NetRoute -DestinationPrefix "192.168.128.0/24" -InterfaceAlias "WAN" -NextHop 192.168.255.128

    #Relai DHCP
    netsh.exe routing ip relay install
    netsh.exe routing ip relay add dhcpserver 192.168.8.1
    netsh.exe routing ip relay add interface "Arc-CLI"
    netsh.exe routing ip relay set interface "Arc-CLI" min=0

    #Arrêt du script
    Remove-Item "C:\config.bat"
}