param (

    [string] $ParamsFile='C:\scripts\RDPGW-Params.csv',
    [string] $LocalPath='C:\tls',
    [string] $PFXPassword=-join ((65..90) + (97..122) | Get-Random -Count 15 | % {[char]$_}),
    [switch] $Install  
)


$Params=Import-Csv $ParamsFile

$SESAccessKey=(Get-SSMParameterValue -Name q4preview-com-ses-notifications-access-key -WithDecryption $true).Parameters.Value
$SESSecretKey=(Get-SSMParameterValue -Name q4preview-com-ses-notifications-secret-key -WithDecryption $true).Parameters.Value

## Get instance public IP from instance meta-data
$PublicIP=(Invoke-WebRequest -Uri http://169.254.169.254/latest/meta-data/public-ipv4 -UseBasicParsing).Content

## Select the RDPGW based on the public IP
$RDPGW=$Params | Where-Object {$_.IP -eq $PublicIP}

$Region=$RDPGW.SQSQueueURL.Split('.')[1]

## Messages comes in 5s: one for each file uploaded to S3

$RenewalTime=$false

do {
    
    $SQSMessage=Receive-SQSMessage -Region $Region -QueueUrl $RDPGW.SQSQueueURL -MessageCount 1

    if($SQSMessage) {
    
        ## Extracts S3 object key that triggered this particular SQS message, slightly different when SQSMsgSource is S3 or SNS
        
        switch ($RDPGW.SQSMsgSource.ToLower()) {
            
            's3' {
            
                $S3Key=(($SQSMessage.Body -join "`n" | ConvertFrom-Json).Records |Select-Object -ExpandProperty s3 | Select-Object -ExpandProperty object).Key  
    
            }
            
            'sns' {
            
                $S3Key=(($SQSMessage.Body -join "`n" | ConvertFrom-Json).Message | ConvertFrom-Json).Records.S3.Object.Key
            }
        }
              
        ## Extract the certificate public key (certificate plus intermediate CA wich is in fullchain.pem) and private key (privkey.pem)
        switch ($S3Key) {
            
            {$_ -like "*privkey.pem*"} { 
                
                
                $CertPrivateKey=$S3Key
                $RenewalTime=$true 
            }
            
            {$_ -like "*fullchain.pem*"} {
                
                $CertPublicKey=$S3Key
            }
        }
        
        ## Delete the message from SQS queue
        Remove-SQSMessage -QueueUrl $RDPGW.SQSQueueURL -Region $Region -ReceiptHandle $SQSMessage.ReceiptHandle -Force            
    }
}

while ($SQSMessage -ne $null)

if ($RenewalTime){

    ## Download the public and private keys from S3

    Read-S3Object -BucketName $RDPGW.S3Bucket -Key $CertPrivateKey -File "$LocalPath\cert-private.pem" -Region $Region

    Read-S3Object -BucketName $RDPGW.S3Bucket -Key $CertPublicKey -File "$LocalPath\cert-public.pem" -Region $Region

    $CurrentFolder=Get-Location

    Set-Location $LocalPath

    openssl pkcs12 -export -out certificate.pfx -inkey cert-private.pem -in cert-public.pem -passout pass:$PFXPassword

    if ($Install) {
        Import-Module RemoteDesktopServices

        $Certificate=Get-PfxData -FilePath certificate.pfx  -Password (ConvertTo-SecureString -String $PFXPassword -Force -AsPlainText) | Select-Object -ExpandProperty EndEntityCertificates

        Import-PfxCertificate -FilePath certificate.pfx -Password (ConvertTo-SecureString -String $PFXPassword -Force -AsPlainText) -Exportable -CertStoreLocation Cert:\LocalMachine\My

        $MostRecentCert=(Get-ChildItem cert:\localmachine\my | where-object {$_.Subject -eq $Certificate.Subject} | Sort-Object -Property NotAfter -Descending | Select-Object -First 1)

        Set-Item -Path RDS:\GatewayServer\SSLCertificate\Thumbprint -Value $MostRecentCert.Thumbprint

        Restart-Service tsgateway

        ## Cleanup SSL folder
        Remove-Item certificate.pfx,cert-private.pem,cert-public.pem -Force

        ## Send SES notification if API keys have been retrieved from the Parameter Store
        if (($SESAccessKey -ne $null) -and ($SESSecretKey -ne $null)) {
            Send-SESEmail -Subject_Data "$($RDPGW.Hostname) SSL Certificate has been renewed!" -Destination_ToAddress infrastructure@q4inc.com -Source SSLRenewals@q4preview.com -Text_Data "Check it out at https://$($RDPGW.Hostname)" -AccessKey $SESAccessKey -SecretKey $SESSecretKey -Region us-east-1
        }
    }

    Set-Location $CurrentFolder

    
}
else {
    
    Write-Output "`nNo messages in the SQS queue. I will try again later."
}

