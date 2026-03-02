@description('The name of the Container Apps Environment')
param name string

@description('The location of the Container Apps Environment')
param location string = resourceGroup().location

@description('Tags to apply to the resource')
param tags object = {}

@description('The name of the Log Analytics workspace')
param logAnalyticsWorkspaceName string

@description('Enable zone redundancy')
param zoneRedundant bool = false

@description('The connection string for Application Insights for Dapr telemetry')
param applicationInsightsConnectionString string = ''

// Get reference to existing Log Analytics workspace
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
    zoneRedundant: zoneRedundant
    daprAIConnectionString: !empty(applicationInsightsConnectionString) ? applicationInsightsConnectionString : null
  }
}

@description('The resource ID of the Container Apps Environment')
output id string = containerAppsEnvironment.id

@description('The name of the Container Apps Environment')
output name string = containerAppsEnvironment.name

@description('The default domain of the Container Apps Environment')
output defaultDomain string = containerAppsEnvironment.properties.defaultDomain

@description('The static IP address of the Container Apps Environment')
output staticIp string = containerAppsEnvironment.properties.staticIp
