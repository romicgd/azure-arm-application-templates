<#
 .SYNOPSIS
    Deploys a single VM, joins to domain and enrolls into OMS workspace 

 .DESCRIPTION
    Deploys a single Windows VM to Azure. 
	- Joins VM to domain using credential in keyvault
	- Enrolls VM into an existing OMS workspace.

 .PARAMETER hostname
    hostname.

.PARAMETER subscriptionId
    The subscription id where the template will be deployed.

 .PARAMETER resourceGroupName
    The resource group where the template will be deployed. Can be the name of an existing or a new resource group.

 .PARAMETER localadminPassword
    The resource group where the template will be deployed. Can be the name of an existing or a new resource group.

 .PARAMETER $domainUsername
    The join domain credentials username name in keyvault.

 .PARAMETER $domainPassword
    The join domain credentials password name in keyvault.

#>

param(
    [Parameter(Mandatory=$true, Position=1)]
    [string]$hostname,

    [Parameter(Mandatory=$True, Position=2)]
    [string]
    $subscriptionId,
   
    [Parameter(Mandatory=$True, Position=3)]
    [string]
    $resourceGroupName,

    [Parameter(Mandatory=$True, Position=4)]
    [string]
    $localadminPassword,

    [Parameter(Mandatory=$True, Position=5)]
    [string]
    $domainUsername,

    [Parameter(Mandatory=$True, Position=6)]
    [string]
    $domainPassword
   )

   
<#
.SYNOPSIS
    Registers RPs
#>
Function RegisterRP {
    Param(
        [string]$ResourceProviderNamespace
    )

    Write-Host "Registering resource provider '$ResourceProviderNamespace'";
    Register-AzureRmResourceProvider -ProviderNamespace $ResourceProviderNamespace;
}

$templateFilePath="./azuredeploy.json";
$resourceGroupLocation="Canada Central"
$parameters = @{}

#******************************************************************************
# Script body
# Execution begins here
#******************************************************************************
$ErrorActionPreference = "Stop"

#******************************************************************************
# Set VM provision parameters
#******************************************************************************
# environment parameters
$parameters.Add("region", "Canada Central")
$parameters.Add("accountRegionEnvironmentPrefix", $accountRegionEnvironmentPrefix)
$parameters.Add("securityZone", $securityZone)
# vm type and size parameters
$parameters.Add("vmName", $host_name)
$parameters.Add("vmHostId", $host_id)
$parameters.Add("imageSku", "2016-Datacenter")
$parameters.Add("storageSku", "Standard_LRS")
$parameters.Add("vmSize", "Standard_D2_v2")
# local admin
$parameters.Add("localadminUsername", "azureadmin")
$parameters.Add("localadminPassword", $localadminPassword)
# workspace
$parameters.Add("workspaceResourceGroup", $workspaceResourceGroup)
$parameters.Add("workspaceName", $workspaceName)
# vnet
$parameters.Add("existingVNETResourceGroupName", "${accountRegionEnvironmentPrefix}rgp01net")
$parameters.Add("existingVNETName", "${accountRegionEnvironmentPrefix}vnetmgt01")
$parameters.Add("subnetName", "${accountRegionEnvironmentPrefix}snet${securityZone}")
# domain join
$parameters.Add("domainToJoin", "<your_domain>")
$parameters.Add("ouPath", "<your_OU_path>")
$parameters.Add("domainUsername", $domainUsername)
$parameters.Add("domainPassword", $domainPassword)
# end-of-vm-parameters

#******************************************************************************
# Azure provisioning starts here
#******************************************************************************
Write-Host "Reserved hostname '$host_name'";

# select subscription
Write-Host "Selecting subscription '$subscriptionId'";
Select-AzureRmSubscription -SubscriptionID $subscriptionId;

# Register RPs
$resourceProviders = @("microsoft.compute","microsoft.network");
if($resourceProviders.length) {
    Write-Host "Registering resource providers"
    foreach($resourceProvider in $resourceProviders) {
        RegisterRP($resourceProvider);
    }
}

#Create or check for existing resource group
$resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if(!$resourceGroup)
{
    Write-Host "Resource group '$resourceGroupName' does not exist. To create a new resource group, please enter a location.";
    if(!$resourceGroupLocation) {
        $resourceGroupLocation = Read-Host "resourceGroupLocation";
    }
    Write-Host "Creating resource group '$resourceGroupName' in location '$resourceGroupLocation'";
    New-AzureRmResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation
}
else{
    Write-Host "Using existing resource group '$resourceGroupName'";
}

# Start the deployment
Write-Host "Starting deployment...";

New-AzureRmResourceGroupDeployment -Debug -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath -TemplateParameterObject $parameters;
