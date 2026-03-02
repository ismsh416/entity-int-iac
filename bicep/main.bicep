targetScope = 'resourceGroup'

@allowed([
  'dev'
  'uat'
  'prod'
])
param environmentName string

@description('Project name used for naming resources')
param projectName string

@description('Azure location')
param location string = resourceGroup().location

@description('Tags applied to all resources')
param tags object = {}

var resourceToken = '${projectName}-${environmentName}-001'

// ======================
// Container Registry
// ======================

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: toLower(replace('cr${resourceToken}', '-', ''))
  location: location
  tags: tags
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
  }
}

// ======================
// Log Analytics
// ======================

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'log-${resourceToken}'
  location: location
  tags: tags
  properties: {
    retentionInDays: 30
  }
}

// ======================
// Container Apps Environment
// ======================

resource containerEnv 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: 'env-${resourceToken}'
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: listKeys(logAnalytics.id, '2022-10-01').primarySharedKey
      }
    }
  }
}

// ======================
// Managed Identity
// ======================

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-${resourceToken}'
  location: location
  tags: tags
}

// ======================
// RBAC - AcrPull
// ======================

resource acrPullRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, identity.id, acr.id)
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '7f951dda-4ed3-4680-a7ca-43fe172d538d' // AcrPull
    )
    principalId: identity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// ======================
// Key Vault
// ======================

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'kv-${resourceToken}'
  location: location
  tags: tags
  properties: {
    tenantId: tenant().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: true
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

// ======================
// RBAC - Key Vault Secrets User
// ======================

resource keyVaultAccess 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, identity.id, 'kv-secrets-user')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '4633458b-17de-408a-b874-0445c86b69e6' // Key Vault Secrets User
    )
    principalId: identity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// ======================
// Outputs
// ======================

output acrName string = acr.name
output acrLoginServer string = acr.properties.loginServer

output containerEnvName string = containerEnv.name
output containerEnvId string = containerEnv.id

output managedIdentityId string = identity.id
output managedIdentityClientId string = identity.properties.clientId

output keyVaultName string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri
