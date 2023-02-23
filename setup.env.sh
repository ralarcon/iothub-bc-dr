#!/bin/bash

## YOU CAN RUN THIS SCRIPT FROM THE AZURE CLI OR FROM THE AZURE CLOUD SHELL
## ENSURE YOU MAKE IT AN EXECUTABLE SCRIPT BY RUNNING: chmod +x setup.env.sh
## RUN THE SCRIPT BY RUNNING: . setup.env.sh or source setup.env.sh (if you want the env vars available in the current shell)

source ${BASH_SOURCE%/*}/variables.sh

echo "Preparing testing environment for BC/DR demo."
echo "SUFIX=$SUFIX"
echo "RSG=$RSG"
echo "RSG_NE=$RSG_NE"
echo "HUB=$HUB"
echo "VNET_WE=$VNET_WE"
echo "VNET_NE=$VNET_NE"
echo 

echo "Creating resource group $RSG"
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
## CREATE RESOURCE GRUOP
az group create --name $RSG --location westeurope
az group create --name $RSG_NE --location northeurope

echo "Creating IoT Hub $HUB"
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
## PROVISION IOT HUB
if [ -n "$(az iot hub list --resource-group $RSG --query "[?name=='$HUB'].id" -o tsv)" ]; then
   echo "$HUB exists"
else
   az iot hub create --resource-group $RSG --name $HUB --sku S1 --partition-count 4
fi
echo "Creating IoT Edge Device 'edge101' and IoT Device 'thermostat1'"
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
## REGISTER DEVICES
if [ -n "$(az iot hub device-identity list --hub-name $HUB --resource-group $RSG --query "[?deviceId=='edge101'].deviceId" -o tsv)" ]; then
   echo "edge101 exists"
else
   az iot hub device-identity create --device-id edge101 --edge-enabled --hub-name $HUB --resource-group $RSG
fi
if [ -n "$(az iot hub device-identity list --hub-name $HUB --resource-group $RSG --query "[?deviceId=='thermostat1'].deviceId" -o tsv)" ]; then
   echo "thermostat1 exists"
else
  az iot hub device-identity create --device-id thermostat1 --hub-name $HUB --resource-group $RSG
fi
## SHOW DEVICES CONN STRINGS
az iot hub device-identity connection-string show --device-id edge101 --hub-name $HUB --resource-group $RSG
az iot hub device-identity connection-string show --device-id thermostat1 --hub-name $HUB --resource-group $RSG

echo "Creating IoT Edge VM"
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
if [ ! -f ~/.ssh/$SSH_KEY_NAME ]; then
  ssh-keygen -f ~/.ssh/$SSH_KEY_NAME -t rsa -b 4096 -C "user@iot-vm"
  echo "An SSH key has been generated at ~/.ssh/$SSH_KEY_NAME."
else
  echo "An SSH key already exists at ~/.ssh/$SSH_KEY_NAME."
fi
PUB_SSH_KEY=$(cat ~/.ssh/$SSH_KEY_NAME.pub)
## DEPLOY VM 
az deployment group create \
--resource-group $RSG \
--template-uri "https://raw.githubusercontent.com/Azure/iotedge-vm-deploy/1.4/edgeDeploy.json" \
--parameters dnsLabelPrefix=$VM_DNS_PREFIX \
--parameters adminUsername='azureUser' \
--parameters deviceConnectionString=$(az iot hub device-identity connection-string show --device-id edge101 --hub-name $HUB --resource-group $RSG -o tsv) \
--parameters authenticationType='sshPublicKey' \
--parameters adminPasswordOrKey="$PUB_SSH_KEY"

echo "Wait for VM to boot"
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
VM_NAME=$(az vm list -g $RSG -d --query "[?starts_with(fqdns,'$VM_DNS_PREFIX')].name" -o tsv)
while true
do
    powerState=$(az vm show --resource-group $RSG --name $VM_NAME -d --query "powerState" -o tsv)
    if [ "$powerState" != "VM running" ]
    then
        echo "VM is booting. Sleeping for a bit..."
        sleep 10
    else
        echo "VM is running. Continuing with script..."
        break
    fi
done

echo "Configuring VM SSH on port 2223"
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
## CONFIGURE VM SSH ON PORT 2223
az vm run-command invoke -g $RSG  -n $VM_NAME --command-id RunShellScript --scripts "sudo sed -i -e 's/#Port 22/Port 2223/' /etc/ssh/sshd_config"
az vm run-command invoke -g $RSG  -n $VM_NAME --command-id RunShellScript --scripts "sudo cat /etc/ssh/sshd_config"
az vm run-command invoke -g $RSG  -n $VM_NAME --command-id RunShellScript --scripts "sudo systemctl restart ssh"

echo "Configuring NSG. Allow port 2223 for SSH and block all outbound traffic."
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
## CONFIGURE NSG
NSG_NAME=$(az network nsg list -g $RSG --query "[].name" -o tsv)
az network nsg rule create --name AllowSSH_2223 --nsg-name $NSG_NAME --priority 2000 --resource-group $RSG --access Allow --source-port-ranges 0-65535 --destination-port-ranges 2223  --direction Inbound --protocol Tcp
az network nsg rule create --resource-group $RSG --nsg-name $NSG_NAME --name BlockInternetTraffic --priority 100 --direction Outbound --access deny --destination-address-prefix Internet --destination-port-range '*' --source-address-prefixes '*' --source-port-range '*'

echo "Configuring VNETs"
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
## SETUP VNETS
VNET_VM=$(az network vnet list -g $RSG --query "[?starts_with(name,'vnet-')].name" -o tsv)
az network vnet create --resource-group $RSG --name $VNET_WE --address-prefix 10.1.0.0/16 --subnet-name default --subnet-prefix 10.1.0.0/24 --location westeurope
az network vnet create --resource-group $RSG_NE --name $VNET_NE --address-prefix 10.2.0.0/16 --subnet-name default --subnet-prefix 10.2.0.0/24 --location northeurope
 
echo "Configuring VNET peering"
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
VNET_WE_ID=$(az network vnet show -g $RSG -n $VNET_WE --query id -o tsv)
VNET_NE_ID=$(az network vnet show -g $RSG_NE -n $VNET_NE --query id -o tsv)
az network vnet peering create --name vnet-onprem-to-vnet-we --resource-group $RSG --vnet-name $VNET_VM --remote-vnet $VNET_WE_ID --allow-vnet-access
az network vnet peering create --name vnet-onprem-to-vnet-ne --resource-group $RSG --vnet-name $VNET_VM --remote-vnet $VNET_NE_ID --allow-vnet-access


echo "Configuring Storage Account"
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
## SETUP STORAGE ACCOUNT
az storage account create --name iotstg$SUFIX --resource-group $RSG --location westeurope --sku Standard_LRS --kind StorageV2

az acr create --resource-group $RSG --name $ACR --sku Premium --admin-enabled true
az acr import --resource-group $RSG --name $ACR --source mcr.microsoft.com/azureiotedge-simulated-temperature-sensor:latest --image azureiotedge-simulated-temperature-sensor:latest --force

## MANUAL ACTIONS
# - ENABLE PRIVATE LINK FOR WE
# Ref: https://learn.microsoft.com/en-us/azure/iot-hub/iot-hub-public-network-access
VM_FQDN=$(az vm show -d --resource-group $RSG --name $VM_NAME --query "fqdns" -o tsv)
echo "To connect to the VM run: ssh -p 2223 azureUser@$VM_FQDN -i ~/.ssh/$SSH_KEY_NAME"
echo "You will need to MANUALLY create the private endpoints (PE) in the WE VNET (and NE when required) for the IoT Hub"
echo "ALSO you need to create the PE for the ACR"
echo "You will need to configure the IoT Edge device (edge101) to deploy the TemperatureSensorModule from the market place"