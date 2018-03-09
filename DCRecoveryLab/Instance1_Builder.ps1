#Set Registry Script Policy
Set-ItemProperty -Path HKLM:SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell -Name ExecutionPolicy -Value "Unrestricted"

#Secure Security Group
$SecurityGroupSecure = Invoke-RestMethod http://169.254.169.254/latest/meta-data/security-groups -Method GET
$InstanceId = Invoke-RestMethod http://169.254.169.254/latest/meta-data/instance-id -Method GET

$VPCId = Get-Ec2Instance -InstanceId $InstanceId
$VpcId = $VPCId.Instances.VpcId
$VPCCidr = Get-Ec2VPC $VPCId | Select CidrBlock
$IpPermissionTCP = New-Object -TypeName Amazon.EC2.Model.IpPermission
$IpPermissionTCP.IpProtocol = 'tcp'
$IpPermissionTCP.FromPort = '0'
$IpPermissionTCP.ToPort = '65535'
$IpPermissionTCP.IpRanges = $VPCCidr.CidrBlock
$IpPermissionUDP = New-Object -TypeName Amazon.EC2.Model.IpPermission
$IpPermissionUDP.IpProtocol = 'udp'
$IpPermissionUDP.FromPort = '0'
$IpPermissionUDP.ToPort = '65535'
$IpPermissionUDP.IpRanges = $VPCCidr.CidrBlock

Grant-EC2SecurityGroupIngress -GroupName $SecurityGroupSecure -IpPermission $IpPermissionTCP
Grant-EC2SecurityGroupIngress -GroupName $SecurityGroupSecure -IpPermission $IpPermissionUDP

#Stage user
net user Auth AWSisLIT123! /add
net localgroup Administrators Auth /add

#Disable firewall
netsh advfirewall set allprofiles state off

#InstallADDS Binaries
Install-WindowsFeature AD-Domain-Services

#Instantiate AWSLabs.com forest
Install-ADDSForest -CreateDnsDelegation:$false -DatabasePath "C:\Windows\NTDS" -DomainMode "Win2012R2" -DomainName "AWSLabs.com" -DomainNetbiosName "AWSLabs" -ForestMode "Win2012R2" -InstallDns:$true -LogPath "C:\Windows\NTDS" -NoRebootOnCompletion:$true -SysvolPath "C:\Windows\SYSVOL" -Force:$true -SafeModeAdministratorPassword ("AWSisLIT123!" | ConvertTo-SecureString -AsPlainText -Force)

$DCIPAddress = Get-NetAdapter | Get-NetIPAddress | where {$_.AddressFamily -eq "IPv4"} | select IPAddress
$DCIPAddress = $DCIPAddress.IPAddress
$DCInstanceID = Invoke-RestMethod http://169.254.169.254/latest/meta-data/instance-id -Method GET

$x = @" 
<powershell>
"$DCInstanceID" | Out-File -FilePath C:\DCInstanceID.txt
Invoke-WebRequest -Uri https://s3.amazonaws.com/labsarecool/Instance2_Destroyer.ps1 -OutFile C:\lab.ps1
Get-NetAdapter | Set-DnsClientServerAddress -ServerAddresses "$DCIPAddress"
C:\lab.ps1
</powershell>
"@
$Scripty = [scriptblock]::Create($x)
$x | Out-File C:\UserData.ps1  -Encoding utf8 -Force

#Scriptblock for Instance 1 boot script
[scriptblock]$AtBoot = {
#Gathering attributes for Instance 2 Launch
$Keypair = Invoke-RestMethod http://169.254.169.254/latest/meta-data/public-keys -Method GET 
$Keypair = $Keypair.Remove(0,2)
$ImageId = Invoke-RestMethod http://169.254.169.254/latest/meta-data/ami-id -Method GET
$AvailabilityZone = Invoke-RestMethod http://169.254.169.254/latest/meta-data/placement/availability-zone -Method GET 
$InstanceProfile = Invoke-RestMethod http://169.254.169.254/latest/meta-data/iam/info -Method Get | select InstanceProfileArn
$InstanceProfile = $InstanceProfile.InstanceProfileArn
$SecurityGroup = Invoke-RestMethod http://169.254.169.254/latest/meta-data/security-groups -Method GET

$TaskAction = New-ScheduledTaskAction –Execute "Powershell.exe" -Argument "-c C:\AddAdmin.ps1 -ExecutionPolicy Bypass"
$TaskTrigger = New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask AddAdmin -Action $TaskAction -Trigger $TaskTrigger -User AWSLabs\Auth -Password 'AWSisLIT123!'
Start-ScheduledTask AddAdmin

New-Ec2Instance -InstanceType m4.large -Keyname $Keypair -ImageId $ImageId -AvailabilityZone $AvailabilityZone -UserDataFile C:\UserData.ps1 -InstanceProfile_Arn $InstanceProfile -EncodeUserData -SecurityGroup $SecurityGroup
}

$AtBoot | Out-file C:\BootScript.ps1 -Width 550
[scriptblock]$AdminAtBoot = {Add-ADGroupMember -Identity "Enterprise Admins" -Members Auth}
$AdminAtBoot | Out-File C:\AddAdmin.ps1 -Width 550

#Creating task for boot script
$TaskPrincipal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$TaskAction = New-ScheduledTaskAction –Execute "Powershell.exe" -Argument "-c C:\BootScript.ps1 -ExecutionPolicy Bypass"
$TaskTrigger = New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask BootScript -Action $TaskAction -Trigger $TaskTrigger -Principal $TaskPrincipal

Restart-Computer -Force