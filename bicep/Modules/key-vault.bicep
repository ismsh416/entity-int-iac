@description('Name of the Key Vault')
@minLength(3)
@maxLength(24)
param keyVaultName string

@description('Location for the Key Vault')
param location string = resourceGroup().location

@description('Key Vault SKU')
@allowed([
  'standard'
  'premium'
])
param skuName string = 'standard'

@description('Tags to apply to the Key Vault')
param tags object = {}

@description('Enable soft delete (recommended)')
param enableSoftDelete bool = true

@description('Soft delete retention period in days')
@minValue(7)
@maxValue(90)
param softDeleteRetentionInDays int = 90

@description('Enable purge protection (recommended for production)')
param enablePurgeProtection bool = false

@description('Enable RBAC authorization instead of access policies')
param enableRbacAuthorization bool = true

@description('Enable public network access')
param publicNetworkAccess string = 'Enabled'

@description('Azure AD Tenant ID')
param tenantId string = tenant().tenantId

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: skuName
    }
    tenantId: tenantId
    enableSoftDelete: enableSoftDelete
    softDeleteRetentionInDays: softDeleteRetentionInDays
    enablePurgeProtection: enablePurgeProtection ? true : null
    enableRbacAuthorization: enableRbacAuthorization
    publicNetworkAccess: publicNetworkAccess
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

@description('The resource ID of the Key Vault')
output keyVaultId string = keyVault.id

@description('The name of the Key Vault')
output keyVaultName string = keyVault.name

@description('The URI of the Key Vault')
output keyVaultUri string = keyVault.properties.vaultUri
