#Affectation
$reseau = "Arc-SRV"
Get-VMNetworkAdapter * | Where-Object {$_.ipaddresses -like "*192.168.8.*"} | Connect-VMNetworkAdapter -SwitchName $reseau
$reseau = "Arc-CLI"
Get-VMNetworkAdapter * | Where-Object {$_.ipaddresses -like "*192.168.12.*"} | Connect-VMNetworkAdapter -SwitchName $reseau
Connect-VMNetworkAdapter -VMName "CLI-01","CLI-02" -SwitchName $reseau
$reseau = "Bou-LAN"
Get-VMNetworkAdapter * | Where-Object {$_.ipaddresses -like "*192.168.128.*"} | Connect-VMNetworkAdapter -SwitchName $reseau
Connect-VMNetworkAdapter -VMName "CLI-03" -SwitchName $reseau
$reseau = "Aston"
Connect-VMNetworkAdapter -VMName "RTR-03" -SwitchName $reseau
$reseau = "WAN"
Get-VMNetworkAdapter * | Where-Object {$_.ipaddresses -like "*192.168.255.*"} | Connect-VMNetworkAdapter -SwitchName $reseau