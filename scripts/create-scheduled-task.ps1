param (
    [string[]] $psScript='C:\scripts\renew-letsencrypt-tls.ps1',
    [string] $Region,
    [string] $S3Bucket,
    [string] $SQSUrl
)


$TaskName=$psScript.Split('\')[-1]

$stAction = New-ScheduledTaskAction -Execute “powershell.exe” -Argument “-Command $psScript -Region $Region -S3Bucket $S3Bucket -SQSUrl $SQSUrl -Install”
$stTrigger =  New-ScheduledTaskTrigger -Daily -At 3am
$stPrincipal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType S4U -RunLevel Highest
$stSettings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit 01:00:00 -Compatibility Win8
    
Register-ScheduledTask -TaskName $TaskName -Action $stAction -Trigger $stTrigger -Principal $stPrincipal -Settings $stSettings

Write-Output "`n Task $TaskName created!"
