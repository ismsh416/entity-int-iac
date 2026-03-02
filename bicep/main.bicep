targetScope = 'resourceGroup'
 
@allowed([
  'dev'

  'uat'

  'prod'

])

param environmentName string
 
param projectName string

param location string = resourceGroup().location
 
@description('Common tags')

param tags object = {}
 
var resourceToken = '${projectName}-${environmentName}-001'
 
// ======================

// Container Registry (Module)

// ======================
 
var containerRegistryName = toLower(replace('cr${resourceToken}', '-', ''))
 
module containerRegistry 'bicep/Modules/container-registry.bicep' = {

  name: 'container-registry-deployment'

  params: {

    name: containerRegistryName

    location: location

    tags: tags

    sku: 'Basic'

    adminUserEnabled: false

    publicNetworkAccess: 'Enabled'

    zoneRedundancyEnabled: false

  }

}
 
// ======================

// Log Analytics

// ======================
 
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {

  name: 'log-${resourceToken}'

  location: location

  properties: {

    retentionInDays: 30

  }

}
 
// ======================

// Container Apps Environment (Module)

// ======================
 
module containerEnv 'bicep/Modules/container-apps-environment.bicep' = {

  name: 'container-env-deployment'

  params: {

    name: 'env-${resourceToken}'

    location: location

    tags: tags

    logAnalyticsWorkspaceName: logAnalytics.name

    zoneRedundant: false

    applicationInsightsConnectionString: ''

  }

}
 
// ======================

// Key Vault (Module)

// ======================
 
module keyVault 'bicep/Modules/key-vault.bicep' = {

  name: 'keyvault-deployment'

  params: {

    keyVaultName: 'kv-${resourceToken}'

    location: location

    skuName: 'standard'

    tags: tags

    enableSoftDelete: true

    softDeleteRetentionInDays: 90

    enablePurgeProtection: environmentName == 'prod'

    enableRbacAuthorization: true

    publicNetworkAccess: 'Enabled'

  }

}
 
// ======================

// Managed Identity

// ======================
 
resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {

  name: 'id-${resourceToken}'

  location: location

}
 
// ======================

// RBAC - AcrPull

// ======================
 
resource acrPullRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {

  name: guid(resourceGroup().id, identity.id, containerRegistry.outputs.id)

  scope: containerRegistry.outputs.id

  properties: {

    roleDefinitionId: subscriptionResourceId(

      'Microsoft.Authorization/roleDefinitions',

      '7f951dda-4ed3-4680-a7ca-43fe172d538d'

    )

    principalId: identity.properties.principalId

    principalType: 'ServicePrincipal'

  }

}
 
// ======================

// RBAC - Key Vault Secrets User

// ======================
 
resource keyVaultSecretsRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {

  name: guid(resourceGroup().id, identity.id, keyVault.outputs.keyVaultId)

  scope: keyVault.outputs.keyVaultId

  properties: {

    roleDefinitionId: subscriptionResourceId(

      'Microsoft.Authorization/roleDefinitions',

      '4633458b-17de-408a-b874-0445c86b69e6'

    )

    principalId: identity.properties.principalId

    principalType: 'ServicePrincipal'

  }

}
 
// ======================

// Outputs

// ======================
 
output containerRegistryName string = containerRegistry.outputs.name

output containerRegistryLoginServer string = containerRegistry.outputs.loginServer

output containerRegistryId string = containerRegistry.outputs.id
 
output containerEnvName string = containerEnv.outputs.name

output containerEnvId string = containerEnv.outputs.id

output containerEnvDomain string = containerEnv.outputs.defaultDomain

output containerEnvStaticIp string = containerEnv.outputs.staticIp
 
output keyVaultName string = keyVault.outputs.keyVaultName

output keyVaultUri string = keyVault.outputs.keyVaultUri

output keyVaultId string = keyVault.outputs.keyVaultId
 
output managedIdentityId string = identity.id
 
