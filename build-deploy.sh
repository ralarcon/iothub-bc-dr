#!/bin/bash

## This script builds the simulator and deploys it to the edge device
## It assumes that the edge device is already created and running
## Ensure that the env.vars.sh script is executable by running: chmod +x env.vars.sh
## Run the script by running: ./build-deploy.sh 

export SUFIX=bcdr
export RSG=iot-$SUFIX
export HUB=iot-$SUFIX-hub
export VM_NAME='edgevm-'$SUFIX
export HOST=$VM_NAME.westeurope.cloudapp.azure.com

source ./IotDeviceSimulator/env.vars.sh

rm -rf ./IotDeviceSimulator/output
VM_NAME=$(az vm list -g $RSG --query "[].name" -o tsv)
az vm run-command invoke -g $RSG  -n $VM_NAME --command-id RunShellScript --scripts "rm -rf /home/azureUser/iot-device-simulator && mkdir /home/azureUser/iot-device-simulator"

dotnet publish ./IotDeviceSimulator/iot-device-simulator.csproj -r linux-x64 --self-contained true --output ./IotDeviceSimulator/output

sed -i 's/##REPLACE_IOT_HUB_CONNSTR##/'$IOT_HUB_CONNSTR'/g' ./IotDeviceSimulator/output/run-simulator.sh
sed -i 's/##REPLACE_DEVICE_CONNSTR##/'$DEVICE_CONNSTR'/g' ./IotDeviceSimulator/output/run-simulator.sh

chmod +x ./IotDeviceSimulator/output/iot-device-simulator.dll

scp -P 2223 -pr ./IotDeviceSimulator/output/*.* azureUser@$HOST:/home/azureUser/iot-device-simulator