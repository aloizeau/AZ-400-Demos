@description('Nom du compte de stockage (3-24 caractères, minuscules et chiffres uniquement)')
@minLength(3)
@maxLength(24)
param name string

@description('Région Azure')
param location string

@description('Tags des ressources')
param tags object

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    networkAcls: {
      // En production, remplacer 'Allow' par 'Deny' et ajouter les règles IP/VNet nécessaires
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

output storageAccountId string = storageAccount.id
output storageAccountName string = storageAccount.name
