param location string = 'global'
@description('The hub VNet resource ID')
param vnetInfo array
param registrationEnabled bool=true

@description('The name of the private DNS zone')
param dnsZoneName string = 'privatednszone.local'

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: dnsZoneName
  location: 'global'
}

resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for vnet in vnetInfo: {
  name: '${dnsZoneName}-${vnet.name}-link'
  parent: privateDnsZone
  location: location
  properties: {
    virtualNetwork: {
      id: vnet.id
    }
    registrationEnabled: registrationEnabled 
  }
}]

output privateDnsZoneName string = privateDnsZone.name


