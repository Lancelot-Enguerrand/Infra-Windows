$nom = "SRV-01"
$int = "Arc-SRV"
$role1 = Get-WindowsFeature DHCP
$role2 = Get-WindowsFeature AD-Domain-Services
$domaine = "aston.local"
$password = 'Pa$$W0rd' | ConvertTo-SecureString -asPlainText -Force

if ($role1.Installed -eq $false)
{
    Install-WindowsFeature DHCP -IncludeManagementTools
    Install-WindowsFeature DNS -IncludeManagementTools
    Rename-Computer $nom
    Set-NetFirewallRule *ICMP4* -Enabled True
    Rename-NetAdapter -Name "Ethernet" -NewName $int
    netsh interface ipv4 set address $int static 192.168.8.1/24 gateway=192.168.8.254
    Set-DnsClientServerAddress -ServerAddresses 192.168.8.1 -InterfaceAlias $int
    Restart-Computer
}
elseif ($role2.Installed -eq $false -and $env:computername -eq $nom)
{
    #DHCP
    $dns = "192.168.8.1"
    $dns2 = "192.168.128.1"
    $suffix = "asrc.local"
    Set-DhcpServerv4OptionValue -DNSServer $dns,$dns2 -DNSDomain "$suffix" -force
    #Arc-CLI
    $prefix = "192.168.12"
    Add-DhcpServerv4Scope -Name "Arcueil" -Description "Clients Arcueil" -StartRange "$prefix.1" -EndRange "$prefix.254" -SubnetMask 255.255.255.0 -Delay 0
    Add-DHCPServerv4ExclusionRange -ScopeID "$prefix.0" -StartRange "$prefix.1" -EndRange "$prefix.31"
    Add-DHCPServerv4ExclusionRange -ScopeID "$prefix.0" -StartRange "$prefix.32" -EndRange "$prefix.63"
    Add-DHCPServerv4ExclusionRange -ScopeID "$prefix.0" -StartRange "$prefix.240" -EndRange "$prefix.254"
    Set-DhcpServerv4OptionValue -ScopeID "$prefix.0"  -Router "$prefix.254" -DNSServer $dns,$dns2 -Force
    #Bou-LAN
    $prefix = "192.168.128"
    Add-DhcpServerv4Scope -Name "Boulogne" -Description "Clients Boulogne" -StartRange "$prefix.1" -EndRange "$prefix.254" -SubnetMask 255.255.255.0 -Delay 0
    Add-DHCPServerv4ExclusionRange -ScopeID "$prefix.0" -StartRange "$prefix.1" -EndRange "$prefix.31"
    Add-DHCPServerv4ExclusionRange -ScopeID "$prefix.0" -StartRange "$prefix.32" -EndRange "$prefix.63"
    Add-DHCPServerv4ExclusionRange -ScopeID "$prefix.0" -StartRange "$prefix.240" -EndRange "$prefix.254"
    Set-DhcpServerv4OptionValue -ScopeID "$prefix.0"  -Router "$prefix.254" -DNSServer $dns2,$dns -Force



    #----------------------------------------------------------------------------------------------------------------------------------------------------------
    #DNS
    $zone = "asrc.local"
    $ttl = "1:00:00"
    $dns1 = "srv-01.$zone"
    $dns2 = "srv-03.$zone"
    Add-DnsServerForwarder 9.9.9.9
    Add-DnsServerPrimaryZone -Name "$zone" -ZoneFile "$zone.dns"  -DynamicUpdate None
    #Correction du NS par défaut srv-01 avec le suffixe
    $mauvaisdns = Get-DnsServerResourceRecord -ZoneName $zone
    $mauvaisdns[0] | Remove-DnsServerResourceRecord -ZoneName "$zone" -Force
    Add-DnsServerResourceRecord -ZoneName "$zone" -NS -Name "$zone" -NameServer "$dns1"
    Add-DnsServerResourceRecord -ZoneName "$zone" -NS -Name "$zone" -NameServer "$dns2"
    Add-DnsServerZoneDelegation -Name "$zone" -ChildZoneName "devs" -NameServer "$dns2" -IPAddress "192.168.128.1"
    #Zone inversée
    Add-DnsServerPrimaryZone –NetworkID “192.168.0.0/16” –ZoneFile “168.192.in-addr.arpa” -DynamicUpdate None
    Add-DnsServerResourceRecordPtr -Name "srv-03" -ZoneName "$zone" -IPv4Address "$prefix.1" -TimeToLive "$ttl"

    #WAN
    $prefix = "192.168.255"
    Add-DnsServerResourceRecordA -Name "nat" -ZoneName "$zone" -IPv4Address "$prefix.254" -TimeToLive "$ttl" -CreatePtr
    Add-DnsServerResourceRecordA -Name "boulogne" -ZoneName "$zone" -IPv4Address "$prefix.128" -TimeToLive "$ttl" -CreatePtr
    Add-DnsServerResourceRecordA -Name "arcueil" -ZoneName "$zone" -IPv4Address "$prefix.8" -TimeToLive "$ttl" -CreatePtr
    #Arc-SRV
    $prefix = "192.168.8"
    Add-DnsServerResourceRecordA -Name "srv-01" -ZoneName "$zone" -IPv4Address "$prefix.1" -TimeToLive "$ttl" -CreatePtr
    Add-DnsServerResourceRecordA -Name "srv-02" -ZoneName "$zone" -IPv4Address "$prefix.2" -TimeToLive "$ttl" -CreatePtr
    #Bou-LAN
    $prefix = "192.168.128"
    Add-DnsServerResourceRecordA -Name "srv-03" -ZoneName "$zone" -IPv4Address "$prefix.1" -TimeToLive "$ttl" -CreatePtr



    #----------------------------------------------------------------------------------------------------------------------------------------------------------
    #Active Directory
    Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
    $InstallationAD = @{
        DomainNetbiosName             = "ASTON"
        NoDnsOnNetwork                = $True
        SkipPreChecks                 = $True
        DomainName                    = $domaine
        SafeModeAdministratorPassword = $password
        CreateDnsDelegation           = $False
        InstallDns                    = $True
        SkipAutoConfigureDns          = $False
        ForestMode                    = "WinThreshold"
        DomainMode                    = "WinThreshold"
        NoRebootOnCompletion          = $False
        Force                         = $True
    }
    Install-ADDSForest @InstallationAD
}
else 
{
    #DNS Zone domaine
    $zone = "aston.local"
    $dns1 = "srv-01.$zone"
    $dns2 = "srv-03.$zone"
    Add-DnsServerResourceRecord -ZoneName "$zone" -NS -Name "$zone" -NameServer "$dns2"
        
    Add-DHCPServerInDC
    New-ADUser -Name "Lancelot-Enguerrand MARLE OUVRARD" -DisplayName "Lancelot-Enguerrand MARLE OUVRARD" -SamAccountName "louvrard" -AccountPassword $Password -Enabled $True -Description "Un homme de style"
    New-ADUser -Name "Lancelot-Enguerrand MARLE OUVRARD - ADM" -DisplayName "Lancelot-Enguerrand MARLE OUVRARD - Administrateur" -SamAccountName "louvrard.adm" -AccountPassword $Password -Enabled $True -Description "Un administrateur de style"
    Add-ADGroupMember -Identity "Administrateurs" -Members louvrard.adm
    Add-ADGroupMember -Identity "Admins du domaine" -Members louvrard.adm

    #Import AD générique
    $comptes = Import-Csv C:\AlimAD.csv
    $comptes | foreach { `
        Write-Host "Creation OU" $_.site
        try {New-ADOrganizationalUnit $_.Site -Path "DC=aston,DC=Local"} catch {"OU Existe Dï¿½jï¿½"}
    
        #Create User
        New-ADUser -name ($_.Prenom + " " + $_.Nom) `
            -Path ('OU=' + $_.Site + ',dc=aston,dc=Local')`
            -Displayname ($_.Prenom + " " + $_.Nom)`
            -AccountPassword $password `
            -ChangePasswordAtLogon $false `
            -City $_.Site `
            -Company "Aston" `
            -Country "FR" `
            -Description $_.Fonction`
            -Department $_.Service `
            -EmailAddress $_.Mail`
            -Enabled $true `
            -Fax $_.'No Fax'`
            -MobilePhone $_.Portable`
            -OfficePhone $_.'No Telephone'`
            -SamAccountName $_.Login`
            -Surname $_.Nom`
            -GivenName $_.Prenom`
            -UserPrincipalName $_.mail`
        
        #Create Groups
        try { `
        New-ADGroup -Name $_.service -SamAccountName $_.service`
            -DisplayName $_.Service `
            -Description ("Utilisateurs du service " + $_.Service) `
            -GroupScope Global `
            -Path ('OU=' + $_.Site + ',dc=aston,dc=Local')`
        }
        Catch {Write-Host "Le groupe "$_.service" existe"}
    
        #Add User to Groups
        Add-ADGroupMember -Identity $_.service  -Members $_.login
    }

    #FIN
    #----------------------------------------------------------------------------------------------------------------------------------------------------------
    #Arrêt du script
    Remove-Item "C:\config.bat"
}