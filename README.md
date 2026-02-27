# AZ-400-Demos

Bienvenue dans le dépôt de démonstrations pour la certification **AZ-400 — Azure DevOps Engineer Expert**.

Ce dépôt regroupe des démonstrations pratiques couvrant les principaux domaines de la formation.

---

## 📂 Démos disponibles

| Démo | Description | Technologies |
|------|-------------|--------------|
| [Demo-Bicep](./Demo-Bicep/README.md) | Déploiement d'une infrastructure Azure complète avec Bicep | Azure Bicep, Azure CLI, GitHub Actions |

---

## 🤖 Pipelines CI/CD

| Workflow | Déclencheur | Description |
|----------|-------------|-------------|
| [Déploiement Bicep](./.github/workflows/bicep-deploy.yml) | Push `main`, PR, manuel | Valide et déploie l'infrastructure Bicep |