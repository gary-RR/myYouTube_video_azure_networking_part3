param reverseZoneName string
param vmName string
param vmIpAddress string

var ipArray = split(vmIpAddress, '.') 

var reversePtrRecordName = '${ipArray[3]}.${ipArray[2]}'

resource reverseDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: reverseZoneName
}

resource reversePtrRecord 'Microsoft.Network/privateDnsZones/PTR@2020-06-01' = {
  name: reversePtrRecordName
  parent: reverseDnsZone 
  properties: {
    ttl: 3600
    ptrRecords: [
      {
        ptrdname: vmName
      }
    ]
  }
}

output reversePtrRecordName string=reversePtrRecordName


