
param vnetName string  
param storageServiceType string = 'blob'

// Dynamic DNS zone name: privatelink.blob.core.windows.net
var privateBlobDnsZoneName = 'privatelink.${storageServiceType}.${environment().suffixes.storage}'

// 1. Get VNet
resource vnet 'Microsoft.Network/virtualNetworks@2020-11-01' existing = {
  name: vnetName
}

resource blobDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateBlobDnsZoneName 
  location: 'global'
}

// Link Blob DNS Zone to VNet
resource blobDnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${vnetName}-link'
  parent: blobDnsZone
  location: 'global'
  properties: {
    registrationEnabled: true
    // The ID of the virtual network to link to the DNS zone
    virtualNetwork: { id: vnet.id }
  }
  dependsOn: [vnet]
}

output blobDnsZoneName string = blobDnsZone.name
output blobDnsZoneVnetLinkName string = blobDnsZoneVnetLink.name
output blobDnsZoneVnetLinkId string = blobDnsZoneVnetLink.id
