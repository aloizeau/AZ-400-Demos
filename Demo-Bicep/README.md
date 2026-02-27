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
# 🚀 Démo AZ-400 — Déploiement Azure avec Bicep

Cette démonstration illustre le déploiement d'une infrastructure Azure complète via **Azure Bicep**, dans le cadre de la formation AZ-400 (Azure DevOps Engineer Expert).

---

## 📐 Architecture déployée

```
Resource Group
├── Log Analytics Workspace    (monitoring)
├── Application Insights        (télémétrie)
├── Storage Account             (stockage)
└── App Service Plan + Web App  (hébergement web)
```

### Ressources créées

| Ressource | Type | Description |
|-----------|------|-------------|
| `log-<appName>-<env>` | Log Analytics Workspace | Centralisation des logs |
| `appi-<appName>-<env>` | Application Insights | Monitoring et télémétrie |
| `st<appName><env>` | Storage Account | Stockage des données |
| `asp-<appName>-<env>` | App Service Plan | Plan d'hébergement |
| `app-<appName>-<env>` | Web App | Application web |

---

## 📁 Structure des fichiers

```
Demo-Bicep/
├── main.bicep                  # Template principal (orchestre les modules)
├── parameters.dev.json         # Paramètres pour l'environnement dev
├── parameters.prod.json        # Paramètres pour l'environnement prod
├── modules/
│   ├── loganalytics.bicep      # Module Log Analytics Workspace
│   ├── appinsights.bicep       # Module Application Insights
│   ├── storage.bicep           # Module Storage Account
│   └── appservice.bicep        # Module App Service Plan + Web App
└── README.md                   # Ce fichier
```

---

## ✅ Prérequis

Avant de commencer, assurez-vous d'avoir installé et configuré les outils suivants :

1. **Azure CLI** (>= 2.50.0)
   ```bash
   az --version
   ```
   📥 [Installer Azure CLI](https://docs.microsoft.com/fr-fr/cli/azure/install-azure-cli)

2. **Extension Bicep pour Azure CLI** (incluse automatiquement)
   ```bash
   az bicep version
   # Si nécessaire, installer manuellement :
   az bicep install
   ```

3. **VS Code** avec l'extension **Bicep** (optionnel, recommandé)
   - Extension ID : `ms-azuretools.vscode-bicep`

4. **Un abonnement Azure actif**
   ```bash
   az account show
   ```

---

## 🔐 Connexion à Azure

```bash
# Se connecter à Azure
az login

# Lister les abonnements disponibles
az account list --output table

# Sélectionner l'abonnement cible
az account set --subscription "<SUBSCRIPTION_ID>"

# Vérifier l'abonnement actif
az account show --output table
```

---

## 🛠️ Déploiement manuel (étape par étape)

### Étape 1 — Cloner le dépôt

```bash
git clone https://github.com/aloizeau/AZ-400-Demos.git
cd AZ-400-Demos/Demo-Bicep
```

### Étape 2 — Créer le Resource Group

```bash
# Variables
RESOURCE_GROUP="rg-az400demo-dev"
LOCATION="westeurope"

# Créer le resource group
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION \
  --tags environment=dev project=AZ-400-Demo managedBy=Bicep
```

### Étape 3 — Valider le template Bicep

```bash
# Valider la syntaxe Bicep (compilation)
az bicep build --file main.bicep

# Valider le déploiement (what-if / dry run)
az deployment group what-if \
  --resource-group $RESOURCE_GROUP \
  --template-file main.bicep \
  --parameters @parameters.dev.json
```

### Étape 4 — Déployer l'infrastructure

```bash
# Déploiement complet
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file main.bicep \
  --parameters @parameters.dev.json \
  --name "deploy-$(date +%Y%m%d-%H%M%S)"
```

### Étape 5 — Vérifier le déploiement

```bash
# Lister toutes les ressources du resource group
az resource list \
  --resource-group $RESOURCE_GROUP \
  --output table

# Obtenir les sorties du déploiement
az deployment group show \
  --resource-group $RESOURCE_GROUP \
  --name "deploy-<TIMESTAMP>" \
  --query "properties.outputs" \
  --output json
```

### Étape 6 — Tester la Web App

```bash
# Récupérer l'URL de la Web App
WEB_APP_URL=$(az deployment group show \
  --resource-group $RESOURCE_GROUP \
  --name "deploy-<TIMESTAMP>" \
  --query "properties.outputs.webAppUrl.value" \
  --output tsv)

echo "URL de la Web App : $WEB_APP_URL"
curl -I $WEB_APP_URL
```

---

## 🔄 Déploiement multi-environnements

### Environnement de développement

```bash
az group create --name "rg-az400demo-dev" --location "westeurope"

az deployment group create \
  --resource-group "rg-az400demo-dev" \
  --template-file main.bicep \
  --parameters @parameters.dev.json \
  --name "deploy-dev-$(date +%Y%m%d-%H%M%S)"
```

### Environnement de production

```bash
az group create --name "rg-az400demo-prod" --location "westeurope"

az deployment group create \
  --resource-group "rg-az400demo-prod" \
  --template-file main.bicep \
  --parameters @parameters.prod.json \
  --name "deploy-prod-$(date +%Y%m%d-%H%M%S)"
```

---

## 🧹 Nettoyage des ressources

> ⚠️ **Attention** : Ces commandes suppriment définitivement les ressources Azure.

```bash
# Supprimer le resource group de développement (et toutes ses ressources)
az group delete \
  --name "rg-az400demo-dev" \
  --yes \
  --no-wait

# Supprimer le resource group de production
az group delete \
  --name "rg-az400demo-prod" \
  --yes \
  --no-wait
```

---

## 🤖 Déploiement automatisé via GitHub Actions

Le pipeline CI/CD est défini dans `.github/workflows/bicep-deploy.yml`.

### Configuration requise

Avant d'utiliser le pipeline automatisé, configurez les secrets et variables suivants dans votre dépôt GitHub :

**Settings → Secrets and variables → Actions → New repository secret**

| Nom | Description | Exemple |
|-----|-------------|---------|
| `AZURE_CREDENTIALS` | Credentials du service principal Azure (JSON) | Voir ci-dessous |

**Settings → Secrets and variables → Actions → Variables**

| Nom | Description | Exemple |
|-----|-------------|---------|
| `AZURE_SUBSCRIPTION_ID` | ID de l'abonnement Azure | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `AZURE_RG_DEV` | Nom du resource group dev | `rg-az400demo-dev` |
| `AZURE_RG_PROD` | Nom du resource group prod | `rg-az400demo-prod` |

### Création du Service Principal Azure

```bash
# Créer un service principal avec le rôle Contributor
az ad sp create-for-rbac \
  --name "sp-az400demo-github" \
  --role Contributor \
  --scopes /subscriptions/<SUBSCRIPTION_ID> \
  --sdk-auth
```

Copiez le JSON complet retourné et ajoutez-le comme secret `AZURE_CREDENTIALS` dans GitHub.

### Déclencheurs du pipeline

| Événement | Action |
|-----------|--------|
| Push sur `main` | Déploiement automatique en **dev** |
| Pull Request vers `main` | Validation (what-if) uniquement |
| Workflow dispatch | Déploiement manuel en **dev** ou **prod** |

---

## 📚 Concepts Bicep illustrés

| Concept | Exemple dans la démo |
|---------|---------------------|
| **Paramètres** | `param environment string` avec `@allowed` |
| **Variables** | Construction des noms de ressources |
| **Modules** | Découpage en `modules/*.bicep` |
| **Outputs** | Retour de l'URL de la Web App |
| **Tags** | Application de tags sur toutes les ressources |
| **Dépendances implicites** | App Insights référence Log Analytics |
| **Managed Identity** | Web App avec `SystemAssigned` |

---

## 🔗 Ressources utiles

- [Documentation Azure Bicep](https://docs.microsoft.com/fr-fr/azure/azure-resource-manager/bicep/)
- [Référence des types de ressources Bicep](https://docs.microsoft.com/fr-fr/azure/templates/)
- [Bicep Playground](https://bicepdemo.z22.web.core.windows.net/)
- [Azure CLI — az deployment](https://docs.microsoft.com/fr-fr/cli/azure/deployment)
- [GitHub Actions pour Azure](https://github.com/Azure/actions)
