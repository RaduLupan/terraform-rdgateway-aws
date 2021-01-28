<powershell>
$computerName="${computer_name}"
$url="${download_url}"

Set-TimeZone -Name "Eastern Standard Time"

if (! (Test-Path "C:\ODT")) {
    New-Item -Path "C:\ODT" -ItemType Container | Out-Null
}

if (! (Test-Path "C:\ODT\Logs")) {
    New-Item -Path "C:\ODT\Logs" -ItemType Container | Out-Null
}

$output = "C:\ODT\odt-installer.exe"

Invoke-WebRequest -Uri $url -OutFile $output

Invoke-Expression "$output /extract:C:\ODT /quiet"

Install-WindowsFeature RDS-RD-Server, RDS-Licensing, RSAT-RDS-Tools -IncludeManagementTools

Rename-Computer -NewName $ComputerName -Force
</powershell>