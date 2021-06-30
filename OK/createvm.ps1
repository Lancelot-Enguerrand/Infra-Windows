#Emplacement Masters
$SRVSRC = "V:\sources\Base_2016_14393.161220_StdGUI_G2_upd28022017.vhdx"
$CLISRC = "V:\sources\Master_Win10_20h2_x86_G1.vhdx"
$ScriptPath = "C:\src\cfg"
$VMList = "RTR-01","RTR-02","RTR-03","SRV-01","SRV-02","SRV-03","CLI-01","CLI-02","CLI-03"
$DC = "SRV-01"

$Switch = Get-VMSwitch
if ($Switch.count -lt 5) {powershell "C:\src\OK\switch.ps1"}

Foreach($VMName in $VMList)
{
    if ($VMName -like "CLI*")
    {
        $Master = $CLISRC
        $Lettre = "E:"
        $Gen = 1
    }
    else
    {
        $Master = $SRVSRC
        $Lettre = "D:"
        $Gen = 2
    }
    New-VHD -Path V:\VHD\$VMNAME.vhdx -ParentPath $Master -Differencing
    Mount-VHD "V:\VHD\$VMName.vhdx"
    Copy-Item "$ScriptPath\config.lnk" "$Lettre\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp"
    Copy-Item "$ScriptPath\config.bat" "$Lettre\"
    Copy-Item "$ScriptPath\$VMName.ps1" "$Lettre\config.ps1"
    if ($VMName -like $DC) {Copy-Item "$ScriptPath\AlimAD.csv" "$Lettre\"} # Ajout du CSV AD pour le DC
    Dismount-VHD "V:\VHD\$VMName.vhdx"
    New-VM -Name $VMName -MemoryStartupBytes 1GB -Generation $Gen -BootDevice VHD -Path V:\VM\ -VHDPATH V:\VHD\$VMName.vhdx
    if ($VMName -like "RTR*")
    {
        Add-VMNetworkAdapter $VMName
        if ($VMName -like "RTR-01")
        {
            Add-VMNetworkAdapter $VMName
        }
        Start-VM $VMName
    }
}

Set-VM -Name * -CheckpointType Disabled  #-ProcessorCount 2
Start-Sleep -Seconds 120
Start-VM $DC
Start-Sleep -Seconds 30
Get-VM * | Where-Object State -eq Off | Start-VM

#Check si toutes les interfaces sont configurées pour y connecter les Switch
$interfaces = Get-VMNetworkAdapter * | Where-Object {$_.ipaddresses -like "*192.168.*"}
while ($interfaces.count -lt 9) #Boucle de temporisation
{
    Start-Sleep -Seconds 10
    $interfaces = Get-VMNetworkAdapter * | Where-Object {$_.ipaddresses -like "*192.168.*"}
}
powershell "C:\src\OK\switch.ps1"