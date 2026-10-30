
targetScope = 'subscription'

param location string = 'uksouth'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-bicep-learning'
  location: location
}

output resourceGroupName string = resourceGroup.name
