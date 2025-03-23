# Assignment2_Azure_IaC

## Commands:

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
