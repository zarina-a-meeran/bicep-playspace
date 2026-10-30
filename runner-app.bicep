
targetScope = 'resourceGroup'

param location string = 'uksouth'

var registryName = 'zarinasacr'
var appName = 'github-runner-app'
var identityName = 'github-runner-identity'
var acrPullRoleId = '7f951dda-4ed3-4680-a7ca-43fe172d538d'

resource containerEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' existing = {
  name: 'cae-runner-learning'
}

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: registryName
}

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
}

resource acrPullAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, identity.id, acrPullRoleId)
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      acrPullRoleId
    )
    principalId: identity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: appName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identity.id}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerEnvironment.id
    configuration: {
      registries: [
        {
          server: '${registryName}.azurecr.io'
          identity: identity.id
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'github-runner'
          image: '${registryName}.azurecr.io/github-runner:v2'
          command: [
            '/home/runner/start.sh'
          ]
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
  }
  dependsOn: [
    acrPullAssignment
  ]
}

output containerAppName string = containerApp.name
output managedIdentityId string = identity.id
