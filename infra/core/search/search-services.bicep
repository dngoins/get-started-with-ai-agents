metadata description = 'Creates an Azure AI Search instance.'
param name string
param location string = resourceGroup().location
param tags object = {}
param projectName string
param serviceName string
param sku object = {
  name: 'standard'
}

param authOptions object = {
  aadOrApiKey: {
    aadAuthFailureMode: 'http401WithBearerChallenge'
  }
}
param disableLocalAuth bool = true
param encryptionWithCmk object = {
  enforcement: 'Unspecified'
}
@allowed([
  'default'
  'highDensity'
])
param hostingMode string = 'default'
param networkRuleSet object = {
  bypass: 'None'
  ipRules: []
}
param partitionCount int = 1
@allowed([
  'enabled'
  'disabled'
])
param publicNetworkAccess string = 'enabled'
param replicaCount int = 1
@allowed([
  'disabled'
  'free'
  'standard'
])
param semanticSearch string = 'disabled'

var searchIdentityProvider = (sku.name == 'free') ? null : {
  type: 'SystemAssigned'
}




resource search 'Microsoft.Search/searchServices@2023-11-01' = {
  name: name
  location: location
  tags: tags  
  sku: {
    name: 'basic'
  }
  identity: searchIdentityProvider  
  properties: {
    authOptions: disableLocalAuth ? null : authOptions
    disableLocalAuth: disableLocalAuth
    encryptionWithCmk: encryptionWithCmk
    hostingMode: hostingMode
    networkRuleSet: networkRuleSet
    partitionCount: partitionCount
    publicNetworkAccess: publicNetworkAccess
    replicaCount: replicaCount
    semanticSearch: semanticSearch
  }
}

resource aiServices 'Microsoft.CognitiveServices/accounts@2025-04-01-preview' existing = {
  name: serviceName

  resource project 'projects' existing = {
    name: projectName

    // AI Project Search Connection
    resource searchConnection 'connections' = {
      name: 'searchConnection'
      // dependsOn: [project] is implicitly handled by 'parent: project'
      properties: {
        category: 'CognitiveSearch'
        authType: 'ApiKey'
        isSharedToAll: true
        target: 'https://${search.name}.search.windows.net/' // search.name will resolve to searchServiceName
        credentials: {
          // This is valid because if this resource is deployed, 'search' is also deployed
          // and 'search.name' (which is 'searchServiceName') is known.
          key: search.listAdminKeys().primaryKey
        }
      }      
    }

  }
}


output id string = search.id
output endpoint string = 'https://${name}.search.windows.net/'
output name string = search.name
output principalId string = !empty(searchIdentityProvider) ? search.identity.principalId : ''
output searchConnectionId string = ''

