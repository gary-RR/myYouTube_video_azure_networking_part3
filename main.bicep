type vmCommonSettingsType = {
  adminUsernam: string
  patchMode: string
  rebootSetting: string
}

param location string = resourceGroup().location
param appName string = 'cosmos'
param storageAccountName string = 'mystorage${uniqueString(resourceGroup().id)}'
param privateEndpointName string = 'myStoragePrivateEndpoint'
param vnetAddressPrefixe string= '10.2.0.0/16'
param subnet1Name string = 'frontendSubnet'
param subnet1SubnetPrefix string = '10.2.1.0/24'
param vpnGateWaySubnetName string = 'GatewaySubnet'
param vpnGatewaySubnetPrefix string = '10.2.2.0/24'
param vnetDNSZoneName string='galaxy.com'
param reverseDnsZoneName string= '10.2.in-addr.arpa'
param sshVmKeyName string
param vmName string = 'vm1'
param vpnClientAddressPrefix string='172.16.201.0/24'
param vmCommonSettings vmCommonSettingsType = {
  adminUsernam: 'gary'
  patchMode: 'AutomaticByPlatform'
  rebootSetting: 'IfRequired'
}

var resourceNameSuffix=uniqueString(resourceGroup().id)
var vnetName= 'vnet1-${appName}-${resourceNameSuffix}'
param storageServiceType string = 'blob'
// Dynamic DNS zone name: privatelink.blob.core.windows.net
var privateBlobDnsZoneName = 'privatelink.${storageServiceType}.${environment().suffixes.storage}'


var subnets = [
  {
    name: subnet1Name
    prefix: subnet1SubnetPrefix
    nsgInfo: {
      enable: false
      nsgId: null
    }
    deligationInfo: {
      enable: false
      delegations: [{}]
    }    
  }
  {
    name: vpnGateWaySubnetName  
    prefix: vpnGatewaySubnetPrefix
    nsgInfo: {
      enable: false
      nsgId: null
    }
    deligationInfo: {
      enable: false
      delegations: [{}]
    }      
  }
]

module createVnet './shared_modules/create_vnet.bicep' = {
  name: 'createVnet'
  params: {
    location: location
    vnetName: vnetName
    vnetAddressPrefixes: vnetAddressPrefixe
    subnets: subnets
  }
}

module vnetDNSZone './shared_modules/create_dns_zone.bicep' = {
  name: 'vnetDNSZone'
  params: {   
    registrationEnabled : true
    vnetInfo: [
      {
        name: vnetName
        id: createVnet.outputs.vnetId
      }
    ]
    dnsZoneName: vnetDNSZoneName   
  }
}

module createvNetReverseDnsZone './shared_modules/create_reverse_dns_zone.bicep' = {
  name: 'createReverseDnsZone'
  params: {   
    
    vnetInfo: [
      {
        name: vnetName
        id: createVnet.outputs.vnetId
      }
    ]
    reverseDnsZoneName: reverseDnsZoneName
  }
}

module createPrivateLinkBlobDnsZone './shared_modules/create_dns_zone.bicep' = {
  name: 'createPrivateLinkBlobDnsZone'
  params: {
    registrationEnabled : false //Only one auto registration is allowed per DNS zone
    vnetInfo: [
      {
        name: vnetName
        id: createVnet.outputs.vnetId
      }
    ]
    dnsZoneName: privateBlobDnsZoneName    
  }
}

module createBlobStorageAccount './shared_modules/create_blob.bicep' = {
  name: 'createBlobStorageAccount'
  params: {
    location: location
    vnetName: vnetName
    subnetName: subnet1Name
    storageAccountName: storageAccountName
    privateEndpointName: privateEndpointName
    privateBlobDnsZoneName: privateBlobDnsZoneName
  }
  dependsOn: [createPrivateLinkBlobDnsZone] //[createBlobDnsZone]
}

module createVm1 './shared_modules/create_vm.bicep' =  {
  name: '${vmName}-module'
  //scope: resouceGroup
  params: {
    sshKeyName: sshVmKeyName
    vmCommonSettings: vmCommonSettings
    vmLinuxName: '${vmName}-${appName}-${resourceNameSuffix}'
    vnetName: createVnet.outputs.vnetName
    subnetName: subnet1Name
    location: location 
  }
}

module createVm1PtrRecord './shared_modules/create_dns_ptr_record.bicep' =  {
  name: 'createVm1PtrRecord'  
  params: {
    reverseZoneName: createvNetReverseDnsZone.outputs.reverseDnsZoneName
    vmIpAddress: createVm1.outputs.vmPrivateIPAddress
    vmName: createVm1.outputs.vmName    
  }
}

module setVmDnsServer './shared_modules/configuer_vm_dns_settings.bicep' = {
  params: {
    vmName: createVm1.outputs.vmName
    domains: vnetDNSZoneName
  }
}

module createVpnGateway './shared_modules/create_vpn_gateway.bicep' = {
  name: 'vcreateVpnGateway'
  params: {
    location: location    
    appName: appName
    vpnGatewaySubnetId: createVnet.outputs.subnets[1].id // '${vnetName}/${vpnGateWaySubnetName}'
    vpnClientAddressPrefix: vpnClientAddressPrefix
  }
}

output storageAccountName string = createBlobStorageAccount.outputs.storageAccountName
output privateEndpointName string = createBlobStorageAccount.outputs.privateEndpointName
output privateEndpointIp string = createBlobStorageAccount.outputs.privateEndpointIp
output vmPrivateIpAddress string = createVm1.outputs.vmPrivateIPAddress
output vmName string = createVm1.outputs.vmName
output vpnGateWayName string = createVpnGateway.outputs.vpnGateWayName
