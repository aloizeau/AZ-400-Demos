# 🏗️ Demo Bicep — Déploiement Azure avec GitHub Actions

Démonstration du déploiement de ressources Azure avec Bicep et GitHub Actions, utilisant une **User-assigned Managed Identity** liée à un agent Azure Container Apps (ACA) pour l'authentification.

## Structure des templates

```
Demo-Bicep/
├── main.bicep                  # Orchestrateur principal
├── parameters.dev.json         # Paramètres environnement DEV
├── parameters.prod.json        # Paramètres environnement PROD
├── README.md                   # Ce fichier
└── modules/
    ├── loganalytics.bicep      # Log Analytics Workspace
    ├── appinsights.bicep       # Application Insights
    ├── storage.bicep           # Compte de stockage
    └── appservice.bicep        # App Service Plan + Web App
```

## Ressources déployées

| Module | Ressource Azure | Description |
|--------|----------------|-------------|
| `loganalytics.bicep` | Log Analytics Workspace | Collecte de logs (PerGB2018, 30 jours) |
| `appinsights.bicep` | Application Insights | Monitoring applicatif (workspace-based) |
| `storage.bicep` | Storage Account | Stockage (TLS 1.2, HTTPS, pas de blob public) |
| `appservice.bicep` | App Service Plan + Web App | Hébergement avec identité SystemAssigned |

## Authentification via User-assigned Managed Identity

Ce workflow utilise une **User-assigned Managed Identity (UAMI)** attachée à l'agent ACA pour s'authentifier auprès d'Azure, **sans secret** stocké dans GitHub.

### Variables GitHub Actions requises

Configurer dans **Settings → Secrets and variables → Actions → Variables** :

| Variable | Description | Exemple |
|----------|-------------|---------|
| `AZURE_CLIENT_ID` | Client ID de la Managed Identity | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `AZURE_TENANT_ID` | ID du tenant Azure AD | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `AZURE_SUBSCRIPTION_ID` | ID de la subscription Azure | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `AZURE_RG_DEV` | Nom du Resource Group DEV | `rg-az400demo-dev` |
| `AZURE_RG_PROD` | Nom du Resource Group PROD | `rg-az400demo-prod` |

> ⚠️ Aucun secret n'est nécessaire : l'authentification repose sur la Managed Identity de l'agent ACA.

## Déploiement manuel (Azure CLI)

### 1. Connexion et préparation

```bash
# Connexion à Azure
az login

# Définir la subscription active
az account set --subscription <SUBSCRIPTION_ID>

# Créer les Resource Groups
az group create --name rg-az400demo-dev --location westeurope
az group create --name rg-az400demo-prod --location westeurope
```

### 2. Validation avec What-If

```bash
# Simulation du déploiement DEV
az deployment group what-if \
  --resource-group rg-az400demo-dev \
  --template-file main.bicep \
  --parameters parameters.dev.json \
  --result-format FullResourcePayloads
```

### 3. Déploiement

```bash
# Déploiement DEV
az deployment group create \
  --resource-group rg-az400demo-dev \
  --template-file main.bicep \
  --parameters parameters.dev.json \
  --name deploy-dev-manual

# Déploiement PROD
az deployment group create \
  --resource-group rg-az400demo-prod \
  --template-file main.bicep \
  --parameters parameters.prod.json \
  --name deploy-prod-manual
```

### 4. Récupération des sorties

```bash
# URL de la Web App DEV
az deployment group show \
  --resource-group rg-az400demo-dev \
  --name deploy-dev-manual \
  --query "properties.outputs.webAppUrl.value" \
  --output tsv
```

### 5. Nettoyage

```bash
az group delete --name rg-az400demo-dev --yes --no-wait
az group delete --name rg-az400demo-prod --yes --no-wait
```

## Configuration de l'agent ACA avec Managed Identity

### Prérequis Azure

1. **Créer la User-assigned Managed Identity** :
   ```bash
   az identity create \
     --name mi-az400demo-runner \
     --resource-group rg-az400demo-infra \
     --location westeurope
   
   # Récupérer le client ID
   az identity show \
     --name mi-az400demo-runner \
     --resource-group rg-az400demo-infra \
     --query clientId --output tsv
   ```

2. **Assigner les rôles nécessaires** à la Managed Identity :
   ```bash
   IDENTITY_PRINCIPAL_ID=$(az identity show \
     --name mi-az400demo-runner \
     --resource-group rg-az400demo-infra \
     --query principalId --output tsv)

   # Rôle Contributor sur la subscription (ou au niveau des RG)
   az role assignment create \
     --role "Contributor" \
     --assignee-object-id $IDENTITY_PRINCIPAL_ID \
     --assignee-principal-type ServicePrincipal \
     --scope /subscriptions/<SUBSCRIPTION_ID>
   ```

3. **Attacher la Managed Identity à l'agent ACA** dans la configuration du Container Apps Job.

### Pipeline GitHub Actions

Le workflow `.github/workflows/bicep-deploy.yml` utilise `auth-type: IDENTITY` avec `client-id` pour spécifier la User-assigned Managed Identity :

```yaml
- name: Connexion à Azure (Managed Identity)
  uses: azure/login@v2
  with:
    auth-type: IDENTITY
    client-id: ${{ vars.AZURE_CLIENT_ID }}
    tenant-id: ${{ vars.AZURE_TENANT_ID }}
    subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}
```

> 💡 `client-id` est obligatoire pour une User-assigned MI afin de spécifier quelle identité utiliser (une ressource peut en avoir plusieurs).
