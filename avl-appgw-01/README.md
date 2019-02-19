# Provision Application Gateway with end-to-end SSL

SSL certificate and Azure Key Vault are loaded into Azure Key Vault.

Note: Since Application Gateway  does not integrate with Azure Key Vault (https://docs.microsoft.com/en-us/azure/application-gateway/application-gateway-faq) certificates we load certificate into Key Value secret as a 64-bit encoded string.

### Load pfx into Azure Key Vault
```powershell
$pfxFilePath = 'your-pfx-path'
$pwd = 'your-pfx-password'
$flag = [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable
$collection = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection 
$collection.Import($pfxFilePath, $pwd, $flag)
$pkcs12ContentType = [System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12
$clearBytes = $collection.Export($pkcs12ContentType, $pwd)
$fileContentEncoded = [System.Convert]::ToBase64String($clearBytes)
$secret = ConvertTo-SecureString -String $fileContentEncoded -AsPlainText –Force
$secretContentType = 'application/x-pkcs12'
Set-AzureKeyVaultSecret -VaultName 'your-key-vault-name' -Name 'pfx-secret-name' -SecretValue $Secret -ContentType $secretContentType
```

### Load public key certificate into Azure Key Vault
Note: Need to remove `-----BEGIN CERTIFICATE-----` and `-----END CERTIFICATE-----` before putting certificate into Azure key Vault.

```powershell
$cerFilePath = 'backend public key cer path'
$certContentEncoded = Get-content $cerFilePath -Raw
$secret = ConvertTo-SecureString -String $certContentEncoded -AsPlainText –Force
$secretContentType = 'txt'
Set-AzureKeyVaultSecret -VaultName 'your-key-vault-name' -Name 'public-key-secret-name' -SecretValue $Secret -ContentType $secretContentType
```
