@description('The name of the Container Registry')
param name string

@description('The location of the Container Registry')
param location string = resourceGroup().location

@description('Tags to apply to the resource')
param tags object = {}

@description('The SKU of the Container Registry')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param sku string = 'Basic'

@description('Enable admin user access')
param adminUserEnabled bool = false

@description('Enable public network access')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'

@description('Enable zone redundancy (requires Premium SKU)')
param zoneRedundancyEnabled bool = false

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: adminUserEnabled
    publicNetworkAccess: publicNetworkAccess
    zoneRedundancy: zoneRedundancyEnabled && sku == 'Premium' ? 'Enabled' : 'Disabled'
    networkRuleBypassOptions: 'AzureServices'
  }
}

@description('The resource ID of the Container Registry')
output id string = containerRegistry.id

@description('The name of the Container Registry')
output name string = containerRegistry.name

@description('The login server URL of the Container Registry')
output loginServer string = containerRegistry.properties.loginServer
