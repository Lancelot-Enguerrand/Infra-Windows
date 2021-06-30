$nom = "SRV-02"
$int = "Arc-SRV"

if ($nom -notlike $env:computername)
{
	Rename-Computer -newname $nom
	Rename-NetAdapter -Name "Ethernet" -NewName $int
	Set-NetFirewallRule *ICMP4* -Enabled True
	netsh interface ipv4 set address $int static 192.168.8.2/24 gateway=192.168.8.254
	Set-DnsClientServerAddress -ServerAddresses 192.168.8.1 -InterfaceAlias $int
	Restart-Computer
}
else
{
    
    $domaine = "aston.local"
    $admindom = "Administrateur"
    $password = 'Pa$$W0rd' | ConvertTo-SecureString -asPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($admindom,$password)
    $Shell = New-Object -ComObject "WScript.Shell"
    $Button = $Shell.Popup("Joindre au domaine ?", 0, "Poste prêt", 0)
    Add-Computer -DomainName $domaine -Credential $credential -Restart -Force

    Remove-Item "C:\config.bat"
}