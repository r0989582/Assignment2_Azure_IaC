# Assignment2_Azure_IaC

This is a school assignment. The objective is to deploy a container to azure with IaC. 
This container should be in a vnet and subnet, be accessible by a public ip on port 80, have rules so only required traffic should be allowed to flow in and out and have logs sent to Azure Monitor.

## Diagram

[Azure Diagram](Assignment2Diagram.jpg)

## Creating the docker image

To create the docker image you will first need to pull the following repository: https://github.com/gurkanakdeniz/example-flask-crud
Then place the dockerfile in this repository into the crud app repository and execute the following command:

```
docker build -t acrrkcrudapp.azurecr.io/mycrudapp .
```

## Deployment Commands

deployAcrOnly is a parameter (bool) that is used to first only create the container registry so the container can be pushed first before the other services.

The following commands can be run via azure CLI in the project directory to deploy the project:

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
