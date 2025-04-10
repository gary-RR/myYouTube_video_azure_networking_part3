param location string = 'global'
param reverseDnsZoneName string ='10.2.in-addr.arpa'
param vnetInfo array


resource reverseDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: reverseDnsZoneName
  location: 'global'
}

resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = [for vnet in vnetInfo: {
  name: '${reverseDnsZoneName}-${vnet.name}-link'
  parent: reverseDnsZone
  location: location
  properties: {
    virtualNetwork: {
      id: vnet.id
    }
    registrationEnabled: false
  }
}]

output reverseDnsZoneName string = reverseDnsZone.name
