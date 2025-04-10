param location string = resourceGroup().location
param vnetName string
param subnetName string
param privateBlobDnsZoneName string //privatelink.blob.core.windows.net
param storageAccountName string = 'mystorage${uniqueString(resourceGroup().id)}' 
param privateEndpointName string = 'myStoragePrivateEndpoint'
param storageServiceType string = 'blob'

param skuName string = 'Standard_LRS' // Default SKU
param kind string = 'StorageV2' // Default kind
param minimumTlsVersion string = 'TLS1_2' // Secure default
param supportsHttpsTrafficOnly bool = true // HTTPS by default
param allowBlobPublicAccess bool = false // No public blobs
param allowSharedKeyAccess bool = true // Allow shared key
param defaultToOAuthAuthentication bool = false // Shared key auth default
param accessTier string = 'Hot' // Default tier
param publicNetworkAccess string = 'Disabled' 
param allowCrossTenantReplication bool = true // Default replication
param networkAclsBypass string = 'AzureServices' // Trusted services bypass
param networkAclsDefaultAction string = 'Allow' // Default action
param networkAclsIpRules array = [] // No IP rules by default
param dnsEndpointType string = 'Standard' // Standard DNS
param largeFileSharesState string = 'Disabled' // Default file shares state
param encryptionKeySource string = 'Microsoft.Storage' // Default key source
param encryptionServicesBlobEnabled bool = true // Blob encryption
param encryptionServicesFileEnabled bool = true // File encryption
param encryptionServicesTableEnabled bool = true // Table encryption
param encryptionServicesQueueEnabled bool = true // Queue encryption
param requireInfrastructureEncryption bool = false // No double encryption



// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: vnetName 
}

// Subnet reference
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {
  name: subnetName
  parent: vnet
}

// Storage Account Resource
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: skuName
  }
  kind: kind
  properties: {
    minimumTlsVersion: minimumTlsVersion
    supportsHttpsTrafficOnly: supportsHttpsTrafficOnly
    allowBlobPublicAccess: allowBlobPublicAccess
    allowSharedKeyAccess: allowSharedKeyAccess
    defaultToOAuthAuthentication: defaultToOAuthAuthentication
    accessTier: accessTier
    publicNetworkAccess: publicNetworkAccess
    allowCrossTenantReplication: allowCrossTenantReplication
    networkAcls: {
      bypass: networkAclsBypass
      defaultAction: networkAclsDefaultAction
      ipRules: networkAclsIpRules
    }
    dnsEndpointType: dnsEndpointType
    largeFileSharesState: largeFileSharesState
    encryption: {
      keySource: encryptionKeySource
      services: {
        blob: {
          enabled: encryptionServicesBlobEnabled
        }
        file: {
          enabled: encryptionServicesFileEnabled
        }
        table: {
          enabled: encryptionServicesTableEnabled
        }
        queue: {
          enabled: encryptionServicesQueueEnabled
        }
      }
      requireInfrastructureEncryption: requireInfrastructureEncryption
    }
  }
  dependsOn: []
}

// Private Endpoint
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: { id: subnet.id }
    privateLinkServiceConnections: [
      {
        name: '${privateEndpointName}-link'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [storageServiceType]
        }
      }
    ]
  }
  dependsOn: [vnet]
}

// Private DNS Zone
resource dnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' existing = {
  name: privateBlobDnsZoneName
}

// Create a DNS A Record
resource dnsRecord 'Microsoft.Network/privateDnsZones/A@2024-06-01' = {
  name: storageAccountName
  parent: dnsZone
  properties: {
    ttl: 300
    aRecords: [
      {
        ipv4Address: privateEndpoint.properties.customDnsConfigs[0].ipAddresses[0]
      }
    ]
  }  
}

output storageAccountName string = storageAccount.name
output privateEndpointName string = privateEndpoint.name
output privateEndpointIp string = privateEndpoint.properties.customDnsConfigs[0].ipAddresses[0]
