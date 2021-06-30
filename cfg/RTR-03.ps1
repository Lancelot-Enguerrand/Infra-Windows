$nom = "RTR-03"

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
    netsh interface ipv4 set address $int static 192.168.255.254/24

    $int="Aston"
    Rename-NetAdapter -Name "Ethernet 2" -NewName $int

    Get-NetAdapter | Set-NetIPInterface -Forwarding Enabled

    #Routes
    New-NetRoute -DestinationPrefix "192.168.8.0/21" -InterfaceAlias "WAN" -NextHop 192.168.255.8
    New-NetRoute -DestinationPrefix "192.168.128.0/24" -InterfaceAlias "WAN" -NextHop 192.168.255.128

    #NAT
    netsh.exe routing ip nat install
    netsh.exe routing ip nat add interface name="WAN" mode=PRIVATE
    netsh.exe routing ip nat add interface name="Aston" mode=FULL
    
    #Arrêt du script
    Remove-Item "C:\config.bat"
}