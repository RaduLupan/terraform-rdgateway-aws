<# 
If the RD Gateway is on only during business hours schedule this script to run at startup to ensure that the latest certificate
deposited in the S3 bucket by the certbot Lambda is downloaded and installed on the RD Gateway server.
#>

param (
    [string] $LocalPath='C:\tls',
    [string] $PFXPassword=-join ((65..90) + (97..122) | Get-Random -Count 15 | % {[char]$_}),
    [string] $Region,
    [string] $S3Bucket,
    [string] $S3Folder
)

# Download the public and private keys from S3 bucket folder where the certbot Lambda saved them.
$CertPrivateKey="$S3Folder/privkey.pem"
$CertPublicKey="$S3Folder/fullchain.pem"

Read-S3Object -BucketName $S3Bucket -Key $CertPrivateKey -File "$LocalPath\cert-private.pem" -Region $Region
Read-S3Object -BucketName $S3Bucket -Key $CertPublicKey -File "$LocalPath\cert-public.pem" -Region $Region

$CurrentFolder=Get-Location

Set-Location $LocalPath

# Use OpenSSL to create .pfx file from the public certificate and private key PEM format.
openssl pkcs12 -export -out certificate.pfx -inkey cert-private.pem -in cert-public.pem -passout pass:$PFXPassword

# Import the certificate from .pfx file, add it to the RD Gateway server and restart tsgateway service.
Import-Module RemoteDesktopServices
$Certificate=Get-PfxData -FilePath certificate.pfx  -Password (ConvertTo-SecureString -String $PFXPassword -Force -AsPlainText) | Select-Object -ExpandProperty EndEntityCertificates
Import-PfxCertificate -FilePath certificate.pfx -Password (ConvertTo-SecureString -String $PFXPassword -Force -AsPlainText) -Exportable -CertStoreLocation Cert:\LocalMachine\My
$MostRecentCert=(Get-ChildItem cert:\localmachine\my | where-object {$_.Subject -eq $Certificate.Subject} | Sort-Object -Property NotAfter -Descending | Select-Object -First 1)
Set-Item -Path RDS:\GatewayServer\SSLCertificate\Thumbprint -Value $MostRecentCert.Thumbprint
Restart-Service tsgateway

# Cleanup $LocalPath folder.
Remove-Item certificate.pfx,cert-private.pem,cert-public.pem -Force

Set-Location $CurrentFolder