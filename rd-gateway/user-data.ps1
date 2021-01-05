<powershell>
$region ="${region}"
$S3Bucket ="${s3_bucket}"
$S3BucketTLS = "${s3_bucket_tls}"
$S3BucketFolderTLS="${s3_folder_tls}"
$SQSUrl = "${sqs_url}"
$HostName = "${host_name}"
$SNSArn = "${sns_arn}"

Set-TimeZone -Name "Eastern Standard Time"

# Install chocolatey.
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

if (! (Test-Path "C:\scripts")) {
    New-Item -Path "C:\scripts" -ItemType Container | Out-Null
}

if (! (Test-Path "C:\OpenSSL-Win64")) {
    New-Item -Path "OpenSSL-Win64" -ItemType Container | Out-Null
}

# Install OpenSSL Light.
Invoke-Expression "choco install openssl.light --params `"/InstallDir:C:\OpenSSL-Win64`" -y"

$PSProfile='C:\Windows\System32\WindowsPowerShell\v1.0\profile.ps1'
$PSProfileContent="`$env:Path += `";C:\OpenSSL-Win64\bin\`"`n`$env:OPENSSL_CONF=`"C:\OpenSSL-Win64\bin\openssl.cfg`""

# Create Powershell profile for all users all hosts.
if (!(Test-Path $PSProfile)) {
    New-Item -Path $PSProfile -ItemType File | Out-Null
    $PSProfileContent | Set-Content $PSProfile
}
else {
    # If a Powershell profile exists append a new line along with the new PSProfileContent.
    $CurrentPSProfile=Get-Content $PSProfile
    ($CurrentPSProfile+"`n"+$PSProfileContent) | Set-Content $PSProfile -Force
}

# Download the Powershell scripts from S3 buket in the C:\scripts folder.
if ($S3Bucket -ne $null) {
    Read-S3Object -BucketName $S3Bucket -Key "${create_task_ps1}" -File "C:${create_task_ps1}" -Region $Region
    Read-S3Object -BucketName $S3Bucket -Key "${renew_tls_ps1}" -File "C:${renew_tls_ps1}" -Region $Region
    Read-S3Object -BucketName $S3Bucket -Key "${get_tls_ps1}" -File "C:${get_tls_ps1}" -Region $Region
}

# Run script1: create-scheduled-task.ps1 to schedule the renew-letsencrypt-tls.ps1 script to run daily.
Invoke-Expression "C:${create_task_ps1} -Region $Region -S3Bucket $S3BucketTLS -SQSUrl $SQSUrl -HostName $HostName -SNSArn $SNSArn -psScript C:${renew_tls_ps1}"

# Run script1: create-scheduled-task.ps1 to schedule the get-latest-letsencrypt-tls.ps1 script to run at system startup.
Invoke-Expression "C:${create_task_ps1} -Region $Region -S3Bucket $S3BucketTLS -S3Folder $S3BucketFolderTLS -psScript C:${get_tls_ps1}"

# Install and configure RD Gateway feature.
Install-WindowsFeature RDS-Gateway,RSAT-RDS-Gateway,RSAT-ADDS,RSAT-DNS-Server
Import-Module RemoteDesktopServices
$GroupName='Administrators';$DomainNetBiosName='BUILTIN'
New-Item -path RDS:\GatewayServer\CAP -Name Default-CAP -UserGroups "$GroupName@$DomainNetBiosName" -AuthMethod 1
New-Item -Path RDS:\GatewayServer\RAP -Name Default-RAP -UserGroups "$GroupName@$DomainNetBiosName" -ComputerGroupType 2
Restart-Service tsgateway
Rename-Computer -NewName "${computer_name}" -Force
</powershell>