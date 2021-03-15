<powershell>
$computerName="${computer_name}"
$url="${download_url}"

$configurationXML=@"
<Configuration>
<Add SourcePath="\\localhost\Software\" OfficeClientEdition="32" >
<Product ID="O365ProPlusRetail">
<Language ID="en-us" />
<ExcludeApp ID="Teams" />
</Product>
</Add>

<!-- <Updates Enabled="TRUE" UpdatePath="\\Server\Share\" /> -->

<Display Level="None" AcceptEULA="TRUE" />
<Property Name="SharedComputerLicensing" Value="1" />

<!-- <Logging Path="%temp%" /> -->

<!-- <Property Name="AUTOACTIVATE" Value="1" /> -->

</Configuration>
"@

Set-TimeZone -Name "Eastern Standard Time"

if (! (Test-Path "C:\ODT")) {
    New-Item -Path "C:\ODT" -ItemType Container | Out-Null
}

if (! (Test-Path "C:\Software")) {
    New-Item -Path "C:\Software" -ItemType Container | Out-Null
}

New-SmbShare -Name Software -Path "C:\Software" -FullAccess "Authenticated Users"

$output = "C:\ODT\odt-installer.exe"

Invoke-WebRequest -Uri $url -OutFile $output

Invoke-Expression "$output /extract:C:\ODT /quiet"

$configurationXML | Set-Content -Path C:\ODT\configuration.xml -Encoding Ascii

Install-WindowsFeature RDS-RD-Server, RSAT-RDS-Tools -IncludeManagementTools

"C:\ODT\setup.exe /download configuration.xml" | Set-Content -Path "C:\ODT\Office365-Download.cmd"
"C:\ODT\setup.exe /configure configuration.xml" | Set-Content -Path "C:\ODT\Office365-Install.cmd"

Rename-Computer -NewName $ComputerName -Force
</powershell>