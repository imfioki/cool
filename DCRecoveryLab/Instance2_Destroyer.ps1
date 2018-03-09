#Set Registry Script Policy
Set-ItemProperty -Path HKLM:SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell -Name ExecutionPolicy -Value "Unrestricted"

#Stage User
net user Auth AWSisLIT123! /add
net localgroup Administrators Auth /add

#Disable Firewall
netsh advfirewall set allprofiles state off

#Creds dawg
$SecPassword = ConvertTo-SecureString "AWSisLIT123!" -AsPlainText -Force
$MyCreds = New-Object System.Management.Automation.PSCredential ("AWSLabs\Auth", $SecPassword)

Install-WindowsFeature AD-Domain-Services

[scriptblock]$AtBoot = {$DCInstanceID = Get-Content C:\DCInstanceID.txt;Remove-EC2Instance -InstanceID $DCInstanceID -Force}
$AtBoot | Out-file C:\BootScript.ps1 -Width 180

#Kick off install of DC into forest. Surpress reboot
Install-ADDSDomainController -InstallDns -Credential $MyCreds -Domain AWSLabs.com -SafeModeAdministratorPassword ("AWSisLIT123!" | ConvertTo-SecureString -AsPlainText -Force) -Force -NoRebootOnCompletion:$true

#Creating task for boot script
$TaskPrincipal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$TaskAction = New-ScheduledTaskAction –Execute "Powershell.exe" -Argument "-c C:\BootScript.ps1 -ExecutionPolicy Bypass"
$TaskTrigger = New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask BootScript -Action $TaskAction -Trigger $TaskTrigger -Principal $TaskPrincipal

Restart-Computer -Force