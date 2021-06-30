$VMname = "*"

Stop-VM $VMname
Remove-VM -Force $VMname
Remove-Item -Recurse -Force "V:\VHD\$VMname"
Remove-Item -Recurse -Force "V:\VM\$VMname"