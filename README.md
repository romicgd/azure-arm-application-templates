# ARM templates for application deployment

## Provision Single VM auto-domain join and OMS workspace enrollment

```powershell
	 ./deploy_single_vm.ps1 $hostname $subscriptionId $resourceGroupName $localadminPassword $domainUsername $domainPassword
```

Join domain with credentials in Azure keyvault credits to https://blogs.msdn.microsoft.com/kaevans/2017/07/15/join-a-virtual-machine-to-existing-domain-with-key-vault-and-arm-templates/