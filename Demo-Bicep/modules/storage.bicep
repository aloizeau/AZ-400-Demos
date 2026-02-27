@description('Nom du compte de stockage (3-24 caractères, minuscules et chiffres uniquement)')
param name string

@description('Région Azure')
param location string

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: name
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
  }
}

output name string = storageAccount.name
output id string = storageAccount.id
