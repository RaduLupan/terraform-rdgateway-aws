param (

    [string] $ParamsFile='C:\latest\RDPGW-Params.csv',
    [string] $LocalPath='C:\tls',
    [string] $PFXPassword=-join ((65..90) + (97..122) | Get-Random -Count 15 | % {[char]$_})
)


$Params=Import-Csv $ParamsFile

## Get instance public IP from instance meta-data
$PublicIP=(Invoke-WebRequest -Uri http://169.254.169.254/latest/meta-data/public-ipv4 -UseBasicParsing).Content

## Select the RDPGW based on the public IP
$RDPGW=$Params | Where-Object {$_.IP -eq $PublicIP}

$Region=$RDPGW.SQSQueueURL.Split('.')[1]

## Download the public and private keys from S3

$CertPrivateKey="letsencrypt-ssl/$($RDPGW.HostName -replace "rdpgw.`",`"`")/privkey.pem"
$CertPublicKey="letsencrypt-ssl/$($RDPGW.HostName -replace "rdpgw.`",`"`")/fullchain.pem"

Read-S3Object -BucketName $RDPGW.S3Bucket -Key $CertPrivateKey -File "$LocalPath\cert-private.pem" -Region $Region

Read-S3Object -BucketName $RDPGW.S3Bucket -Key $CertPublicKey -File "$LocalPath\cert-public.pem" -Region $Region

$CurrentFolder=Get-Location

Set-Location $LocalPath

openssl pkcs12 -export -out certificate.pfx -inkey cert-private.pem -in cert-public.pem -passout pass:$PFXPassword

Import-Module RemoteDesktopServices

$Certificate=Get-PfxData -FilePath certificate.pfx  -Password (ConvertTo-SecureString -String $PFXPassword -Force -AsPlainText) | Select-Object -ExpandProperty EndEntityCertificates

Import-PfxCertificate -FilePath certificate.pfx -Password (ConvertTo-SecureString -String $PFXPassword -Force -AsPlainText) -Exportable -CertStoreLocation Cert:\LocalMachine\My

$MostRecentCert=(Get-ChildItem cert:\localmachine\my | where-object {$_.Subject -eq $Certificate.Subject} | Sort-Object -Property NotAfter -Descending | Select-Object -First 1)

Set-Item -Path RDS:\GatewayServer\SSLCertificate\Thumbprint -Value $MostRecentCert.Thumbprint

Restart-Service tsgateway

Remove-Item certificate.pfx,cert-private.pem,cert-public.pem -Force

Set-Location $CurrentFolder