# Assignment2_Azure_IaC

This is a school assignment. The objective is to deploy a container to azure with IaC. 
This container should be in a vnet and subnet, be accessible by a public ip on port 80, have rules so only required traffic should be allowed to flow in and out and have logs sent to Azure Monitor.

## Commands:
deployAcrOnly is a parameter (bool) that is used to first only create the container registry so the container can be pushed first before the other services.

```
az group create -l eastus -n RkCruddGroup
```
```
az deployment group create --resource-group RkCruddGroup --template-file deploy.bicep --parameters deployAcrOnly=true
```
```
az acr login --name acrrkcrudapp
```
```
docker push acrrkcrudapp.azurecr.io/mycrudapp:latest
```
```
az deployment group create --resource-group RkCruddGroup --template-file deploy.bicep --parameters deployAcrOnly=false
```
```
az group delete --name RkCruddGroup --yes --no-wait
```
