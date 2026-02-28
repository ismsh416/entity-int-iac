param location string = 'eastus'
param containerAppName string
param environmentName string

resource env 'Microsoft.App/managedEnvironments@2023-08-01-preview' = {
  name: environmentName
  location: location
}

resource containerApp 'Microsoft.App/containerApps@2023-08-01-preview' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: env.id
    configuration: {
      ingress: {
        external: true
        targetPort: 8080
      }
    }
    template: {
      containers: [
        {
          name: 'entity-api'
          image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
          resources: {
            cpu: 0.5
            memory: '1Gi'
          }
        }
      ]
    }
  }
}