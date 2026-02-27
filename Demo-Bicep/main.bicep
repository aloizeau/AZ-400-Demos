@description('Environnement de déploiement (dev, staging, prod)')
@allowed(['dev', 'staging', 'prod'])
param environment string = 'dev'

@description('Région Azure pour le déploiement des ressources')
param location string = resourceGroup().location

@description('Nom de l\'application (sans espaces, en minuscules)')
@minLength(3)
@maxLength(20)
param appName string

@description('SKU du plan App Service')
@allowed(['F1', 'B1', 'B2', 'S1', 'S2', 'P1v2', 'P2v2'])
param appServicePlanSku string = 'B1'

@description('Tags communs appliqués à toutes les ressources')
param tags object = {
  environment: environment
  project: 'AZ-400-Demo'
  managedBy: 'Bicep'
}

// Variables pour la construction des noms de ressources
var resourceSuffix = '${appName}-${environment}'
var appServicePlanName = 'asp-${resourceSuffix}'
var webAppName = 'app-${resourceSuffix}'
var storageAccountName = 'st${replace(toLower(appName), '-', '')}${environment}'
var appInsightsName = 'appi-${resourceSuffix}'
var logAnalyticsName = 'log-${resourceSuffix}'

// Module : Log Analytics Workspace
module logAnalytics 'modules/loganalytics.bicep' = {
  name: 'deploy-loganalytics'
  params: {
    name: logAnalyticsName
    location: location
    tags: tags
  }
}

// Module : Application Insights
module appInsights 'modules/appinsights.bicep' = {
  name: 'deploy-appinsights'
  params: {
    name: appInsightsName
    location: location
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
    tags: tags
  }
}

// Module : Compte de stockage
module storageAccount 'modules/storage.bicep' = {
  name: 'deploy-storage'
  params: {
    name: storageAccountName
    location: location
    tags: tags
  }
}

// Module : App Service Plan + Web App
module appService 'modules/appservice.bicep' = {
  name: 'deploy-appservice'
  params: {
    appServicePlanName: appServicePlanName
    webAppName: webAppName
    location: location
    sku: appServicePlanSku
    appInsightsConnectionString: appInsights.outputs.connectionString
    appInsightsInstrumentationKey: appInsights.outputs.instrumentationKey
    storageAccountId: storageAccount.outputs.storageAccountId
    tags: tags
  }
}

// Sorties
output webAppUrl string = appService.outputs.webAppUrl
output webAppName string = appService.outputs.webAppName
output storageAccountName string = storageAccount.outputs.storageAccountName
output appInsightsName string = appInsights.outputs.appInsightsName
