#!/bin/bash

## This script builds the simulator and deploys it to the edge device
## It assumes that the edge device is already created and running
## Ensure that the env.vars.sh script is executable by running: chmod +x env.vars.sh
## Run the script by running: ./build-deploy.sh 

export SUFIX=bcdr
export RSG=iot-$SUFIX
export HUB=iot-$SUFIX-hub
export VM_DNS_PREFIX='edgevm-'$SUFIX
export SSH_KEY_NAME=iot_vm_rsa

source ./IotDeviceSimulator/env.vars.sh

echo "Cleaning up simulator output folder."
rm -rf ./IotDeviceSimulator/output

echo "Cleaning up simulator folder on edge device."
VM_NAME=$(az vm list -g $RSG -d --query "[?starts_with(fqdns,'$VM_DNS_PREFIX')].name" -o tsv)
az vm run-command invoke -g $RSG -n $VM_NAME --command-id RunShellScript --scripts "rm -rf /home/azureUser/iot-device-simulator && mkdir /home/azureUser/iot-device-simulator && chown azureUser /home/azureUser/iot-device-simulator"

echo "Publish content."
dotnet publish ./IotDeviceSimulator/iot-device-simulator.csproj -c release -r linux-x64 --self-contained true --output ./IotDeviceSimulator/output

sed -i 's/##REPLACE_IOT_HUB_CONNSTR##/'$IOT_HUB_CONNSTR'/g' ./IotDeviceSimulator/output/run-simulator.sh
sed -i 's/##REPLACE_DEVICE_CONNSTR##/'$DEVICE_CONNSTR'/g' ./IotDeviceSimulator/output/run-simulator.sh

chmod +x ./IotDeviceSimulator/output/iot-device-simulator

echo "Copying simulator to edge device."
VM_FQDN=$(az vm show -d --resource-group $RSG --name $VM_NAME --query "fqdns" -o tsv)
scp -P 2223 -i ~/.ssh/$SSH_KEY_NAME -pr ./IotDeviceSimulator/output/* azureUser@$VM_FQDN:/home/azureUser/iot-device-simulator

echo "To run the simulator, run remotely the run-simulator.sh script with the following command:"
echo "ssh -p 2223 -i ~/.ssh/$SSH_KEY_NAME azureUser@$VM_FQDN \"cd /home/azureUser/iot-device-simulator/;./run-simulator.sh\""