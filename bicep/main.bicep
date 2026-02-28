targetScope = 'resourceGroup'

@allowed([
  'dev'
  'uat'
  'prod'
])
param environmentName string

param projectName string
param location string = resourceGroup().location

var resourceToken = '${projectName}-${environmentName}-001'

// ======================
// Container Registry
// ======================

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: toLower(replace('cr${resourceToken}', '-', ''))
  location: location
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
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  }
}

// ======================
// User Assigned Managed Identity
// ======================

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-${resourceToken}'
  location: location
}

// ======================
// RBAC - AcrPull Role Assignment
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
// Outputs
// ======================

output acrName string = acr.name
output acrLoginServer string = acr.properties.loginServer
output containerEnvName string = containerEnv.name
output managedIdentityId string = identity.id