<powershell>
$ComputerName="${computer_name}"

Set-TimeZone -Name "Eastern Standard Time"

Rename-Computer -NewName $ComputerName -Force
</powershell>