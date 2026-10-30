
targetScope = 'resourceGroup'

param location string = 'uksouth'

@minLength(5)
@maxLength(50)
param registryName string = 'zarinasacr'

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: registryName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
  }
}

output registryLoginServer string = acr.properties.loginServer
