param (
    [string] $psScript,
    [string] $Region,
    [string] $S3Bucket,
    [string] $S3Folder="",
    [string] $SQSUrl="",
    [string] $HostName="",
    [string] $SNSArn=""
)

$TaskName=$psScript.Split('/')[-1]

switch ($psScript) {
    
    # Schedule renew-letsencrypt-tls.ps1 script to run daily to catch the renewal date.
    'C:/scripts/renew-letsencrypt-tls.ps1' {
        $stAction = New-ScheduledTaskAction -Execute "powershell.exe" `
        -Argument "-Command $psScript -Region $Region -S3Bucket $S3Bucket -SQSUrl $SQSUrl -HostName $HostName -SNSArn $SNSArn -Install"
        $stTrigger =  New-ScheduledTaskTrigger -Daily -At 3am            
    }
    
    # Schedule get-latest-letsencrypt-tls.ps1 to run at startup in case the instance missed the renewal.
    'C:/scripts/get-latest-letsencrypt-tls.ps1' {
        $stAction = New-ScheduledTaskAction -Execute "powershell.exe" `
        -Argument "-Command $psScript -Region $Region -S3Bucket $S3Bucket -S3Folder $S3Folder"
        $stTrigger =  New-ScheduledTaskTrigger -AtStartup
    }
}


$stPrincipal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType S4U -RunLevel Highest
$stSettings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit 01:00:00 -Compatibility Win8
    
Register-ScheduledTask -TaskName $TaskName -Action $stAction -Trigger $stTrigger -Principal $stPrincipal -Settings $stSettings

Write-Output "`n Task $TaskName created!"
