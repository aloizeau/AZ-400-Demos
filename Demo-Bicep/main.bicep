@description('Nom de l\'application (utilisé pour nommer les ressources)')
param appName string

@description('Environnement de déploiement')
@allowed(['dev', 'prod'])
param environment string = 'dev'

@description('Région Azure de déploiement')
param location string = resourceGroup().location

@description('SKU du plan App Service')
param appServiceSkuName string = 'B1'

var prefix = '${appName}-${environment}'

module logAnalytics 'modules/loganalytics.bicep' = {
  name: 'loganalytics-deploy'
  params: {
    name: '${prefix}-law'
    location: location
  }
}

module appInsights 'modules/appinsights.bicep' = {
  name: 'appinsights-deploy'
  params: {
    name: '${prefix}-ai'
    location: location
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
  }
}

module storage 'modules/storage.bicep' = {
  name: 'storage-deploy'
  params: {
    name: toLower(replace('${appName}${environment}st', '-', ''))
    location: location
  }
}

module appService 'modules/appservice.bicep' = {
  name: 'appservice-deploy'
  params: {
    name: prefix
    location: location
    skuName: appServiceSkuName
    appInsightsConnectionString: appInsights.outputs.connectionString
    storageAccountName: storage.outputs.name
  }
}

output webAppUrl string = appService.outputs.webAppUrl
output appInsightsKey string = appInsights.outputs.instrumentationKey
