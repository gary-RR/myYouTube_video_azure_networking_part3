param location string = 'global'
@description('The hub VNet resource ID')
param hubVNetId string

@description('The spoke1 VNet resource ID')
param spoke1VNetId string

@description('The spoke2 VNet resource ID')
param spoke2VNetId string

@description('The name of the private DNS zone')
param dnsZoneName string = 'privatednszone.local'

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: dnsZoneName
  location: 'global'
}

resource reverseDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: '10.in-addr.arpa'
  location: 'global'
}

resource hubVNetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${dnsZoneName}-hub-link'
  parent: privateDnsZone
  location: location
  properties: {
    virtualNetwork: {
      id: hubVNetId
    }
    registrationEnabled: true
  }
}

resource spoke1VNetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${dnsZoneName}-spoke1-link'
  parent: privateDnsZone
  location: location
  properties: {
    virtualNetwork: {
      id: spoke1VNetId
    }
    registrationEnabled: true
  }
}

resource spoke2VNetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${dnsZoneName}-spoke2-link'
  parent: privateDnsZone
  location: location
  properties: {
    virtualNetwork: {
      id: spoke2VNetId
    }
    registrationEnabled: true
  }
}

resource reverseVNetLinkHub 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '10.in-addr.arpa-hub-link'
  parent: reverseDnsZone
  location: location
  properties: {
    virtualNetwork: {
      id: hubVNetId
    }
    registrationEnabled: false
  }
}

resource reverseVNetLinkSpoke1 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '10.in-addr.arpa-spoke1-link'
  parent: reverseDnsZone
  location: location
  properties: {
    virtualNetwork: {
      id: spoke1VNetId
    }
    registrationEnabled: false
  }
}

resource reverseVNetLinkSpoke2 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '10.in-addr.arpa-spoke2-link'
  parent: reverseDnsZone
  location: location
  properties: {
    virtualNetwork: {
      id: spoke2VNetId
    }
    registrationEnabled: false
  }
}

output reverseDnsZone string=reverseDnsZone.name

