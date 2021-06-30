$nom = "CLI-03"
$int = "Bou-LAN"

if ($nom -notlike $env:computername)
{
    Rename-Computer $nom
    Rename-NetAdapter -Name "Ethernet" -NewName $int
    Set-NetFirewallRule *ICMP4* -Enabled True
    Set-Service wuauserv -StartupType Disabled
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

    #Arrêt du script
    Remove-Item "C:\config.bat"
    Restart-Computer
} 