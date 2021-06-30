$nom = "SRV-03"
$int = "Bou-LAN"

if ($nom -notlike $env:computername)
{
    Install-WindowsFeature DNS -IncludeManagementTools
    Rename-Computer -newname $nom
    Rename-NetAdapter -Name "Ethernet" -NewName $int
    Set-NetFirewallRule *ICMP4* -Enabled True
    netsh interface ipv4 set address $int static 192.168.128.1/24 gateway=192.168.128.254
    Set-DnsClientServerAddress -ServerAddresses 192.168.8.1 -InterfaceAlias $int
    Restart-Computer
}
else
{
    #DNS asrc
    $zone="asrc.local"
    Add-DnsServerForwarder 9.9.9.9
    Add-DnsServerSecondaryZone -Name "$zone" -ZoneFile "$zone.dns" -MasterServers "192.168.8.1"
    #Zone Devs
    $zone="devs.$zone"
    Add-DnsServerPrimaryZone -Name "$zone" -ZoneFile "$zone.dns"
    $zone="asrc.devs"
    Add-DnsServerPrimaryZone -Name "$zone" -ZoneFile "$zone.dns"
    
    #Domaine Aston.local
    $zone="aston.local"
    Add-DnsServerSecondaryZone -Name "$zone" -ZoneFile "$zone.dns" -MasterServers "192.168.8.1"

    #File Server
    Install-WindowsFeature File-Services -IncludeManagementTools
    
    $domaine = "aston.local"
    $admindom = "Administrateur"
    $password = 'Pa$$W0rd' | ConvertTo-SecureString -asPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($admindom,$password)
    $Shell = New-Object -ComObject "WScript.Shell"
    $Button = $Shell.Popup("Joindre au domaine ?", 0, "Poste prêt", 0)
    Add-Computer -DomainName $domaine -Credential $credential -Restart -Force

    Remove-Item "C:\config.bat"
}