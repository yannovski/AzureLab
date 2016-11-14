Param (
    [string]$certificateName = "MyLab01RemoteAccess",
    [string]$certificatePassword = "P@55w0rd",
    [string]$certificatePath = "c:\",
    [string]$armTemplatePath = "C:\Source\irobins\MyLab01\MyLab01\azuredeploy.json",
    [string]$armParamPath = "C:\Source\irobins\MyLab01\MyLab01\azuredeploy.parameters.json",
    [string]$resourcegroupname = "MyLab01",
    [string]$certificateStore = "my",
    [string]$azureregion = 'westeurope'
)

# Create new self signed cert
$thumbprint = (New-SelfSignedCertificate -DnsName $certificateName -CertStoreLocation "Cert:\CurrentUser\$certificateStore" -KeySpec KeyExchange).Thumbprint

# Get the new cert
$certificate = (Get-ChildItem -Path "cert:\CurrentUser\$certificateStore\$thumbprint")

# Convert password param to secure string
$securePassword = ConvertTo-SecureString -AsPlainText $certificatePassword -Force

# Define path to export certificate to
$certificatePath = "$certificatePath\$certificateName.pfx"

# Export as PFX (so it has the private key)
Export-PfxCertificate -Cert $certificate -FilePath $certificatePath -Password $securePassword

# Read the certificate file
$fileContentBytes = Get-Content $certificatePath -Encoding Byte
# Convert the bytes to base64
$fileContentEncoded = [System.Convert]::ToBase64String($fileContentBytes)

# Generate JSON object for the encoded PFX
$jsonObject = @"
{
  "data": $filecontentencoded,
  "dataType" :"pfx",
  "password": $securePassword
}
"@

# Encode the JSON object
$jsonObjectBytes = [System.Text.Encoding]::UTF8.GetBytes($jsonObject)
$jsonEncoded = [System.Convert]::ToBase64String($jsonObjectBytes)

# Convert encoded JSON to secure string
$secret = ConvertTo-SecureString -String $jsonEncoded -AsPlainText –Force

# Cleanup cert
Remove-item $certificatePath -Force
$certificate | Remove-Item

# Check to see if the resource group already exists
$ResourceGroup = Get-AzureRmResourceGroup -Name $resourcegroupname

# If not, create it
If ($ResourceGroup -eq $null) {
    New-AzureRmResourceGroup -Name $resourcegroupname -Location $azureregion
}

$DeploymentParameters = @{
    'secretValue' = $secret;
}

New-AzureRmResourceGroupDeployment -Name ((Get-ChildItem $armTemplatePath).BaseName + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')) -ResourceGroupName $ResourceGroupName -TemplateFile $armTemplatePath -TemplateParameterFile $armParamPath @DeploymentParameters -Force -Verbose 

