# COMPLETE SETUP STEPS (From Scratch)

## PHASE 1 --- Azure Initial Setup

### 1. Create Resource Group

az group create --name poc-rg --location eastus

### 2. Create App Registration (Service Principal)

-   Go to Microsoft Entra ID → App registrations → New registration
-   Note:
    -   Application (client) ID
    -   Directory (tenant) ID

### 3. Create Client Secret

-   Certificates & secrets → New client secret
-   Copy the secret VALUE

### 4. Assign Role to Service Principal

az login az role assignment create\
--assignee `<CLIENT_ID>`{=html}\
--role Owner\
--scope /subscriptions/`<SUBSCRIPTION_ID>`{=html}

------------------------------------------------------------------------

## PHASE 2 --- GitHub Setup

### 5. Add GitHub Secret

Secret Name: AZURE_CREDENTIALS

{ "clientId": "xxx", "clientSecret": "xxx", "subscriptionId": "xxx",
"tenantId": "xxx" }

------------------------------------------------------------------------

## PHASE 3 --- Infrastructure (IAC Repo)

### 6. Create Bicep Files

Provision: - Azure Container Registry - Log Analytics Workspace -
Container Apps Environment - Managed Identity - RBAC (AcrPull)

### 7. Create Environment Parameter Files

Example: dev.bicepparam

using './main.bicep'

param environmentName = 'dev' param projectName = 'entityint' param
location = 'eastus'

### 8. Deploy Infrastructure

az deployment group create\
--resource-group poc-rg\
--template-file bicep/main.bicep\
--parameters bicep/dev.bicepparam

------------------------------------------------------------------------

## PHASE 4 --- Application (API Repo)

### 9. CI/CD Pipeline Steps

-   Azure login
-   Gradle build
-   Docker build
-   Docker push to ACR
-   Create/Update Container App
-   Set min-replicas = 0
-   Print API URL

### 10. Container App Deployment

az containerapp create\
--environment env-entityint-dev-001\
--image crentityintdev001.azurecr.io/entity-api:`<commit-sha>`{=html}\
--min-replicas 0\
--max-replicas 1

------------------------------------------------------------------------

## PHASE 5 --- Verification

### 11. Verify ACR

az acr list -o table

### 12. Verify Container App

az containerapp list -g poc-rg -o table

### 13. Get API URL

az containerapp show\
--name entity-api-dev\
--resource-group poc-rg\
--query properties.configuration.ingress.fqdn\
-o tsv

------------------------------------------------------------------------

## PHASE 6 --- Cost Optimization

### 14. Scale to Zero

az containerapp update\
--name entity-api-dev\
--resource-group poc-rg\
--min-replicas 0

------------------------------------------------------------------------

## Architecture Summary

Infra Repo: - Platform provisioning - Identity & RBAC - Logging setup

App Repo: - Image build - Deployment - Scaling control

------------------------------------------------------------------------

## End-to-End Flow Summary

1.  Create Service Principal + assign Owner
2.  Store credentials in GitHub
3.  Deploy Infra via Bicep
4.  Deploy App via CI/CD
5.  Scale to zero for cost control