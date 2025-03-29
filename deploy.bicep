param deployAcrOnly bool = false //zorgt ervoor dat eerst enkel acr gemaakt kan worden om container te pushen

param location string = 'eastus'
param acrName string = 'acrrkcrudapp'
param containerGroupName string = 'mycrudapp'
param containerName string = 'mycrudapp'
param vnetName string = 'crudVnet'
param subnetName string ='crudSubnet'
param loadBalancerName string = 'crudBalancer'
param containerImage string = 'acrrkcrudapp.azurecr.io/mycrudapp:latest'

resource acr 'Microsoft.ContainerRegistry/registries@2024-11-01-preview' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = if (!deployAcrOnly){
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.1.0/24'
          delegations: [ //staat toe dat er containers gemaakt mogen worden in dit subnet
            {
              name: 'containerDelegation'
              properties: {
                serviceName: 'Microsoft.ContainerInstance/containerGroups'
              }
            }
          ]
        }
      }
    ]
  }
}

resource publicIP 'Microsoft.Network/publicIPAddresses@2024-05-01' = if (!deployAcrOnly){
  name: 'crudPublicIp'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource loadBalancer 'Microsoft.Network/loadBalancers@2024-05-01' = if (!deployAcrOnly){
  name: loadBalancerName
  location: 'eastus'
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'crudFrontendIp'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIP.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'crudBackendPool'
        properties: {
          loadBalancerBackendAddresses: [
            {
              name: 'b38e1c02-6871-4140-9756-56e2dd0b289a'
              properties: {
                ipAddress: '10.0.1.4'
                virtualNetwork: {
                  id: vnet.id
                }
              }
            }
          ]
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'CrudBalanceRuleIn'
        properties: {
          frontendPort: 80
          backendPort: 80
          enableFloatingIP: false
          idleTimeoutInMinutes: 4
          protocol: 'Tcp'
          enableTcpReset: false
          loadDistribution: 'Default'
          disableOutboundSnat: true
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadBalancerName, 'crudFrontendIp')
         }
         backendAddressPool: {
          id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerName, 'crudBackendPool')
       }
        }
      }
    ]
    probes: [ //health check
      {
        name: 'crudProbe'
        properties: {
          protocol: 'Tcp'
          port: 80
          intervalInSeconds: 5
          numberOfProbes: 1
          probeThreshold: 1
          noHealthyBackendsBehavior: 'AllProbedDown'
        }
      }
    ]
    inboundNatRules: []
    outboundRules: [
      {
        name: 'CrudBalanceRuleOut'
        properties: {
          allocatedOutboundPorts: 0
          protocol: 'All'
          enableTcpReset: true
          idleTimeoutInMinutes: 4
          backendAddressPool:{
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerName, 'crudBackendPool')
          }
          frontendIPConfigurations: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadBalancerName, 'crudFrontendIp')
            }
          ]
        }
      }
    ]
    inboundNatPools: []
  }
}

resource loadbalancer_backendPool 'Microsoft.Network/loadBalancers/backendAddressPools@2024-05-01' = if (!deployAcrOnly){
  parent: loadBalancer
  name: 'crudBackendPool'
  properties: {
    loadBalancerBackendAddresses: [
      {
        name: 'backendAdress1'
        properties: {
          ipAddress: '10.0.1.4'
          virtualNetwork: {
            id: vnet.id
          }
        }
      }
      {
        name: 'backendAdress2'
        properties: {
          ipAddress: '10.0.1.5'
          virtualNetwork: {
            id: vnet.id
          }
        }
      }
    ]
  }
}

resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = if (!deployAcrOnly){
  name: containerGroupName
  location: location
  properties: {
    containers: [
      {
        name: containerName
        properties: {
          image: containerImage
          ports: [
            {
              protocol: 'TCP'
              port: 80
            }
          ]
          resources: {
            requests: {
              cpu: 1
              memoryInGB: 1
            }
          }
        }
      }
    ]
    ipAddress: {
      ports: [
        {
          protocol: 'TCP'
          port: 80
        }
      ]
      ip: '10.0.1.4'
      type: 'Private'
    }
    osType: 'Linux'
    subnetIds: [
      {
        id: vnet.properties.subnets[0].id
      }
    ]
    imageRegistryCredentials: [ // haalt credentials op van acr zodat dit niet manueel moet altijd
      {
        server: acr.properties.loginServer 
        username: acr.properties.adminUserEnabled ? acr.listCredentials().username : ''
        password: acr.properties.adminUserEnabled ? acr.listCredentials().passwords[0].value : ''
      }
    ]
  }
}

resource containerGroup2 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = if (!deployAcrOnly){
  name: '${containerGroupName}${2}'
  location: location
  properties: {
    containers: [
      {
        name: containerName
        properties: {
          image: containerImage
          ports: [
            {
              protocol: 'TCP'
              port: 80
            }
          ]
          resources: {
            requests: {
              cpu: 1
              memoryInGB: 1
            }
          }
        }
      }
    ]
    ipAddress: {
      ports: [
        {
          protocol: 'TCP'
          port: 80
        }
      ]
      ip: '10.0.1.5'
      type: 'Private'
    }
    osType: 'Linux'
    subnetIds: [
      {
        id: vnet.properties.subnets[0].id
      }
    ]
    imageRegistryCredentials: [ // haalt credentials op van acr zodat dit niet manueel moet altijd
      {
        server: acr.properties.loginServer 
        username: acr.properties.adminUserEnabled ? acr.listCredentials().username : ''
        password: acr.properties.adminUserEnabled ? acr.listCredentials().passwords[0].value : ''
      }
    ]
  }
}
