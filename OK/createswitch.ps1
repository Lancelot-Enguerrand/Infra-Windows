#Creation Switch
New-VMSwitch -Name Arc-SRV -SwitchType Private
New-VMSwitch -Name Arc-CLI -SwitchType Private
New-VMSwitch -Name Bou-LAN -SwitchType Private
New-VMSwitch -Name WAN -SwitchType Private
New-VMSwitch -Name Aston -NetAdapterName Ethernet