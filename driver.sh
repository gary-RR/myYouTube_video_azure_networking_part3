location='eastus'
env='test'
resourceGroup='create_storage_private_link_'$env
ssh_Vm_Key_Name='vm1_sshkey'

az group create --name $resourceGroup --location $location

existing_files="v$(ls ~/.ssh)"
az sshkey create --name $ssh_Vm_Key_Name --resource-group $resourceGroup 
new_files=$(ls ~/.ssh | grep -v -f <(echo "$existing_files"))
ssh_Vm_Key_file_Name=$(echo "$new_files" | grep -v '\.pub$')


az deployment group create --resource-group ${resourceGroup} --name create_storage_private_link   --template-file ./private_links/main.bicep \
    --parameters sshVmKeyName=${ssh_Vm_Key_Name} 

vpnGateWayName=$(az deployment group show -g ${resourceGroup}  -n create_storage_private_link  --query "properties.outputs.vpnGateWayName.value" -o tsv)
echo $vpnGateWayName
vmPrivateIpAddress=$(az deployment group show -g ${resourceGroup}  -n create_storage_private_link  --query "properties.outputs.vmPrivateIpAddress.value" -o tsv) 
echo $vmPrivateIpAddress
vmName=$(az deployment group show -g ${resourceGroup}  -n create_storage_private_link  --query "properties.outputs.vmName.value" -o tsv)
echo $vmName

privateEndpointIp=$(az deployment group show -g ${resourceGroup}  -n create_storage_private_link  --query "properties.outputs.privateEndpointIp.value" -o tsv)
echo $privateEndpointIp

storageAccountName=$(az deployment group show -g ${resourceGroup}  -n create_storage_private_link  --query "properties.outputs.storageAccountName.value" -o tsv)
echo $storageAccountName

clientVPNConfigFileURL=$(az network vnet-gateway vpn-client generate --name $vpnGateWayName --resource-group ${resourceGroup})
clientVPNConfigFileURL="${clientVPNConfigFileURL//\"/}"
echo $clientVPNConfigFileURL
curl -o vpnClientConfig.zip $clientVPNConfigFileURL
unzip -o vpnClientConfig.zip 


alias sshVm1='ssh -i ~/.ssh/$ssh_Vm_Key_file_Name gary@$vmPrivateIpAddress'

sshVm1 "nslookup $vmPrivateIpAddress"
sshVm1 "nslookup $vmName"
sshVm1 "cat /etc/resolv.conf"

nslookup $storageAccountName.blob.core.windows.net
sshVm1 "nslookup $storageAccountName.blob.core.windows.net"

nslookup $storageAccountName.privatelink.blob.core.windows.net
sshVm1 "nslookup $storageAccountName.privatelink.blob.core.windows.net"

nslookup -type=CNAME $storageAccountName.blob.core.windows.net
sshVm1 "nslookup -type=CNAME $storageAccountName.blob.core.windows.net"

nslookup -type=CNAME $storageAccountName.privatelink.blob.core.windows.net
sshVm1 "nslookup -type=CNAME $storageAccountName.privatelink.blob.core.windows.net"


az group delete --name ${resourceGroup} --yes --no-wait