targetScope = 'subscription'

@description('Nom du Resource Group à créer ou mettre à jour')
@minLength(1)
param resourceGroupName string

@description('Région Azure du Resource Group')
param location string

@description('Tags à appliquer au Resource Group')
param tags object = {}

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

output resourceGroupId string = rg.id
output resourceGroupName string = rg.name
