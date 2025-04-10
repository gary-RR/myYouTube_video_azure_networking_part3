param vmName string
param location string=resourceGroup().location
param dns string='168.63.129.16'
param domains string='privatednszone.local'

resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' existing =  {
  name: vmName  
}

resource vmExtension 'Microsoft.Compute/virtualMachines/extensions@2024-07-01' = {
  name: 'modifyResolvConf'
  parent: vm
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    settings: {
      commandToExecute: 'sh -c \'echo "DNS=${dns}\\nDomains=${domains}" >> /etc/systemd/resolved.conf && sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf && sudo systemctl restart systemd-resolved\''
    }
  }
}

