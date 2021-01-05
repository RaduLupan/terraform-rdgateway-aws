<# 
If the RD Gateway is on 24 x 7 schedule this script to run every day so that when new certificates are deposited in the S3 bucket by the certbot Lambda,
the script will receive the corresponding SQS messages and download the new certificate and install it on the RD Gateway server.
#>

param (
    [string] $LocalPath='C:\tls',
    [string] $PFXPassword=-join ((65..90) + (97..122) | Get-Random -Count 15 | % {[char]$_}),
    [string] $Region,
    [string] $SQSUrl,
    [string] $S3Bucket,
    [string] $HostName,
    [string] $SNSArn,
    [switch] $Install  
)

if (! (Test-Path $LocalPath)) {
    New-Item -Path $LocalPath -ItemType Container | Out-Null
}

# Messages comes in 5s: one for each file uploaded to S3.
$RenewalTime=$false

do {
    
    $SQSMessage=Receive-SQSMessage -Region $Region -QueueUrl $SQSUrl -MessageCount 1

    if($SQSMessage) {
    
        # Extract S3 object key that triggered this particular SQS message.
        $S3Key=(($SQSMessage.Body -join "`n" | ConvertFrom-Json).Records |Select-Object -ExpandProperty s3 | Select-Object -ExpandProperty object).Key  
                      
        # Extract the certificate public key (certificate plus intermediate CA wich is in fullchain.pem) and private key (privkey.pem).
        switch ($S3Key) {
            
            {$_ -like "*privkey.pem*"} { 
                
                
                $CertPrivateKey=$S3Key
                $RenewalTime=$true 
            }
            
            {$_ -like "*fullchain.pem*"} {
                
                $CertPublicKey=$S3Key
            }
        }
        
        # Delete the message from SQS queue.
        Remove-SQSMessage -QueueUrl $SQSUrl -Region $Region -ReceiptHandle $SQSMessage.ReceiptHandle -Force            
    }
}

while ($SQSMessage -ne $null)

if ($RenewalTime){

    # Download the public and private keys from S3 bucket folder letsencrypt-tls where the certbot Lambda saved them.
    Read-S3Object -BucketName $S3Bucket -Key $CertPrivateKey -File "$LocalPath\cert-private.pem" -Region $Region
    Read-S3Object -BucketName $S3Bucket -Key $CertPublicKey -File "$LocalPath\cert-public.pem" -Region $Region

    $CurrentFolder=Get-Location

    Set-Location $LocalPath

    # Use OpenSSL to create .pfx file from the public certificate and private key PEM format.
    openssl pkcs12 -export -out certificate.pfx -inkey cert-private.pem -in cert-public.pem -passout pass:$PFXPassword

    if ($Install) {
        # Import the certificate from .pfx file, add it to the RD Gateway server and restart tsgateway service.
        Import-Module RemoteDesktopServices
        $Certificate=Get-PfxData -FilePath certificate.pfx  -Password (ConvertTo-SecureString -String $PFXPassword -Force -AsPlainText) | Select-Object -ExpandProperty EndEntityCertificates
        Import-PfxCertificate -FilePath certificate.pfx -Password (ConvertTo-SecureString -String $PFXPassword -Force -AsPlainText) -Exportable -CertStoreLocation Cert:\LocalMachine\My
        $MostRecentCert=(Get-ChildItem cert:\localmachine\my | where-object {$_.Subject -eq $Certificate.Subject} | Sort-Object -Property NotAfter -Descending | Select-Object -First 1)
        Set-Item -Path RDS:\GatewayServer\SSLCertificate\Thumbprint -Value $MostRecentCert.Thumbprint
        Restart-Service tsgateway

        # Cleanup $LocalPath folder.
        Remove-Item certificate.pfx,cert-private.pem,cert-public.pem -Force

        Publish-SNSMessage -TopicArn $SNSArn -Message "$HostName TLS certificate has been renewed! Check it out at https://$HostName"
    }

    Set-Location $CurrentFolder    
}
else {
    
    Write-Output "`nNo messages in the SQS queue. I will try again later."
}

