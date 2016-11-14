$certificateName = "MyLab01RemoteAccess"

$thumbprint = (New-SelfSignedCertificate -DnsName $certificateName -CertStoreLocation Cert:\CurrentUser\My -KeySpec KeyExchange).Thumbprint

$cert = (Get-ChildItem -Path cert:\CurrentUser\My\$thumbprint)

$password = ConvertTo-SecureString -AsPlainText "P@55w0rd" -Force

$path = "c:\$certificateName.pfx"

Export-PfxCertificate -Cert $cert -FilePath $path -Password $password

$fileContentBytes = Get-Content $path -Encoding Byte
$fileContentEncoded = [System.Convert]::ToBase64String($fileContentBytes)

$jsonObject = @"
{
  "data": "$filecontentencoded",
  "dataType" :"pfx",
  "password": "P@55w0rd"
}
"@

$jsonObjectBytes = [System.Text.Encoding]::UTF8.GetBytes($jsonObject)
$jsonEncoded = [System.Convert]::ToBase64String($jsonObjectBytes)

$secret = ConvertTo-SecureString -String $jsonEncoded -AsPlainText –Force

$VaultName = 'Mylab01KeyVault01'
$SecretName = 'MyLab01Cert01'

Set-AzureKeyVaultSecret -VaultName $VaultName -Name $SecretName -SecretValue $secret


$cred = Get-Credential
Enter-PSSession -ConnectionUri https://13.94.235.195:5986 -Credential $cred -SessionOption (New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck) -Authentication Negotiate